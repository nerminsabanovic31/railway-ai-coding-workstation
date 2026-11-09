# AI Coding Workstation

A cloud workstation for coding agents, deployable to Railway in one click. Open it in any browser, including on a phone, and get:

- **VS Code in the browser** (code-server) with a full terminal, file tree and extensions
- **A lightweight web terminal** at `/terminal`, running a persistent tmux session
- **Claude Code, OpenAI Codex, Gemini CLI and OpenCode** pre-installed and updated on every boot
- **Persistent storage**: your home folder, agent logins and projects live on a Railway volume
- **One password** protects everything

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/ai-coding-workstation)

## Variables

| Variable | Required | What it does |
| --- | --- | --- |
| `PASSWORD` | yes | Password for VS Code and the web terminal (user `dev` on the terminal) |
| `ANTHROPIC_API_KEY` | no | Use Claude Code with an API key instead of signing in |
| `OPENAI_API_KEY` | no | Use Codex with an API key instead of signing in |
| `GEMINI_API_KEY` | no | Use Gemini CLI with an API key instead of signing in |
| `GITHUB_TOKEN` | no | Lets `git` and `gh` push to your repositories |
| `GIT_USER_NAME`, `GIT_USER_EMAIL` | no | Git commit identity |
| `AUTO_UPDATE_AGENTS` | no | `true` by default; set `false` to keep the image's agent versions |

## Signing in with a subscription

- **Claude Code**: run `claude` and open the login link it prints. Paste the code back into the terminal.
- **Codex**: run `codex login --device-auth` and enter the code at the URL it shows.
- **Gemini CLI**: run `gemini` and pick "Login with Google".

Logins are saved in `/data/home`, so you only do this once.

## Layout

- `/data/projects`: your code (VS Code opens here)
- `/data/home`: home directory for user `dev` (passwordless sudo)
- Tools: Node.js 22, Python 3 with uv and pipx, git, GitHub CLI, tmux, ripgrep, fd, jq, build-essential

## Tips

- Close the browser tab at any time: agents keep running inside tmux. Reattach with `tmux a -t main`.
- Give the service at least 2 GB of memory if you run several agents at once.
- Run long jobs with `claude -p "..."` or `codex exec "..."` inside tmux to let them work while you are away.

## License

MIT
