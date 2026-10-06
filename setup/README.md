# Developer Environment Setup

One-time setup for a fresh machine with VS Code. Installs and configures:

| Tool | Notes |
|------|-------|
| **Git** | Includes **Git Bash** on Windows (set as VS Code's default terminal) |
| **Python 3.14** | Current stable line. Override with `-PythonVersion 3.13` / `PYTHON_VERSION=3.13` |
| **uv, pipx, ruff** | Fast package/venv manager, CLI tool installer, linter/formatter |
| **Node.js LTS + npm** | For JS tooling, Copilot Studio / Power Platform CLIs |
| **GitHub CLI (`gh`)** | Auth and PRs from the terminal |
| **PowerShell 7, Windows Terminal** | Windows only |
| **Claude Code** | CLI (`claude`) via the official installer + `anthropic.claude-code` VS Code extension |
| **Claude Desktop** | Windows (via winget). On macOS: `brew install --cask claude` |
| **VS Code extensions** | Listed in [`vscode-extensions.txt`](vscode-extensions.txt) |

## 1. Get this repo onto your machine

If Git isn't installed yet, download the repo as a ZIP from GitHub
(**Code → Download ZIP**) and extract it. After setup, clone it properly with Git.

## 2. Run the script

### Windows

**Easiest:** double-click `setup\setup-windows.cmd` and enter your name and email when prompted.

Or from PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\setup\setup-windows.ps1 -GitName "Your Name" -GitEmail "you@example.com"
```

VS Code is expected at `%LOCALAPPDATA%\Programs\Microsoft VS Code`
(i.e. `C:\Users\<you>\AppData\Local\Programs\Microsoft VS Code`); pass `-VSCodeDir "<path>"` if it's elsewhere.

Requires `winget` (preinstalled on Windows 10 21H2+/11; otherwise install **App Installer** from the Microsoft Store).

### macOS / Linux

```bash
bash setup/setup-unix.sh "Your Name" "you@example.com"
```

## 3. After the script

1. **Restart VS Code** and any open terminals so PATH updates take effect.
2. Sign in to GitHub: `gh auth login`
3. Sign in to Claude Code: run `claude` in a terminal (opens the browser), or click the
   Claude icon in VS Code's sidebar. Open **Claude Desktop** from the Start menu and sign in.
4. Clone your repo: `git clone https://github.com/ShAhasni/ShAhasni.git`
5. Create a project virtual environment:
   ```bash
   uv venv            # creates .venv
   uv pip install -r requirements.txt   # when the project has one
   ```
   VS Code picks up `.venv` automatically (see `.vscode/settings.json`).

## Verify

```bash
git --version
python --version     # Windows: py --version
node --version
gh --version
claude --version
code --list-extensions
```

## What's in the repo

- `.vscode/settings.json` – format-on-save, Ruff for Python, Prettier for JSON/MD/YAML, `.venv` interpreter
- `.vscode/extensions.json` – VS Code prompts to install recommended extensions on open
- `.editorconfig`, `.gitattributes` – consistent indentation and line endings across Windows/macOS/Linux
- `.gitignore` – Python, Node and OS clutter
