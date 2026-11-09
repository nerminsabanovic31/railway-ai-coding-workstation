#!/usr/bin/env bash
# Boots the workstation: persistent home on the volume, then VS Code,
# the web terminal and Caddy. Exits when any of them dies so Railway restarts it.
set -euo pipefail

if [ -z "${PASSWORD:-}" ]; then
  echo "PASSWORD is not set. Add it in Railway → Variables and redeploy." >&2
  exit 1
fi

WORKSPACE="${WORKSPACE:-/data}"
HOME_DIR="$WORKSPACE/home"
PROJECTS="$WORKSPACE/projects"

# Everything that should survive a redeploy lives on the volume
mkdir -p "$HOME_DIR" "$PROJECTS"
if [ ! -f "$HOME_DIR/.bashrc" ]; then
  cp -rT /etc/skel "$HOME_DIR"
  cat >> "$HOME_DIR/.bashrc" <<'EOF'

# AI Coding Workstation
export PATH="/opt/agents/bin:$HOME/.local/bin:$PATH"
[ -n "${GITHUB_TOKEN:-}" ] && export GH_TOKEN="$GITHUB_TOKEN"
cd "${PROJECTS_DIR:-/data/projects}" 2>/dev/null || true
[ -z "${WORKSTATION_QUIET:-}" ] && workstation-info
EOF
fi
usermod -d "$HOME_DIR" dev
chown dev:dev "$WORKSPACE" "$HOME_DIR" "$PROJECTS"
chown -R dev:dev "$HOME_DIR" 2>/dev/null || true

as_dev() {
  sudo --preserve-env -u dev HOME="$HOME_DIR" PROJECTS_DIR="$PROJECTS" "$@"
}

# Optional git identity and GitHub auth
[ -n "${GIT_USER_NAME:-}" ] && as_dev git config --global user.name "$GIT_USER_NAME"
[ -n "${GIT_USER_EMAIL:-}" ] && as_dev git config --global user.email "$GIT_USER_EMAIL"
if [ -n "${GITHUB_TOKEN:-}" ]; then
  as_dev env GH_TOKEN="$GITHUB_TOKEN" gh auth setup-git >/dev/null 2>&1 || true
fi

export PASSWORD_HASH
PASSWORD_HASH="$(caddy hash-password --plaintext "$PASSWORD")"

# code-server would otherwise bind to $PORT, which belongs to Caddy
as_dev env -u PORT code-server \
  --bind-addr 127.0.0.1:8443 \
  --auth password \
  --disable-telemetry \
  --disable-update-check \
  --app-name "AI Coding Workstation" \
  "$PROJECTS" &

as_dev ttyd \
  --interface 127.0.0.1 --port 7681 \
  --base-path /terminal \
  --writable \
  --client-option fontSize=15 \
  --client-option titleFixed="AI Coding Workstation" \
  tmux new-session -A -s main &

caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
SERVICES="$(jobs -p)"

# Keep the agents current without delaying startup
if [ "${AUTO_UPDATE_AGENTS:-true}" = "true" ]; then
  (
    timeout 300 sudo -u dev HOME="$HOME_DIR" npm install -g --prefix /opt/agents \
      @anthropic-ai/claude-code @openai/codex @google/gemini-cli opencode-ai >/dev/null 2>&1 \
      && echo "Coding agents updated." \
      || echo "Agent update skipped; using the built-in versions."
  ) &
fi

# shellcheck disable=SC2086
wait -n $SERVICES
echo "A workstation process exited; restarting the container." >&2
exit 1
