# AI Coding Workstation: Claude Code, Codex, Gemini CLI and OpenCode
# in a browser IDE and a browser terminal, on one password-protected port.
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_MAJOR=22
ARG TTYD_VERSION=1.7.7

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl wget gnupg git git-lfs openssh-client sudo locales tzdata \
      build-essential pkg-config python3 python3-pip python3-venv pipx \
      tmux htop nano vim less unzip zip jq ripgrep fd-find tree rsync procps iproute2 dnsutils \
 && locale-gen en_US.UTF-8 \
 && ln -s /usr/bin/fdfind /usr/local/bin/fd \
 && rm -rf /var/lib/apt/lists/*

# Node.js and GitHub CLI
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
 && mkdir -p -m 755 /etc/apt/keyrings \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update && apt-get install -y --no-install-recommends nodejs gh \
 && rm -rf /var/lib/apt/lists/*

# uv for Python projects
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

# Browser IDE, browser terminal and the reverse proxy in front of both
RUN curl -fsSL https://code-server.dev/install.sh | sh \
 && curl -fsSL -o /usr/local/bin/ttyd \
      https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.$(uname -m) \
 && chmod +x /usr/local/bin/ttyd
COPY --from=caddy:2 /usr/bin/caddy /usr/local/bin/caddy

# Coding agents, installed into a user-owned prefix so they can update themselves
ENV NPM_CONFIG_PREFIX=/opt/agents \
    PATH=/opt/agents/bin:$PATH
RUN mkdir -p /opt/agents \
 && npm install -g @anthropic-ai/claude-code @openai/codex @google/gemini-cli opencode-ai \
 && npm cache clean --force

# Non-root user with passwordless sudo (Claude Code refuses some modes as root)
RUN userdel -r ubuntu 2>/dev/null || true \
 && useradd -m -s /bin/bash -u 1000 dev \
 && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev \
 && chown -R dev:dev /opt/agents

COPY Caddyfile /etc/caddy/Caddyfile
COPY rootfs/ /
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/workstation-info

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    WORKSPACE=/data \
    PORT=8080

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
