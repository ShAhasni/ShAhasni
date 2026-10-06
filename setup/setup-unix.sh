#!/usr/bin/env bash
# One-time developer environment setup for macOS or Linux (Debian/Ubuntu, Fedora).
# Installs: Git, Python (via uv), Node.js LTS, GitHub CLI, and VS Code extensions.
#
# Usage:
#   bash setup/setup-unix.sh "Your Name" "you@example.com"
set -euo pipefail

GIT_NAME="${1:-}"
GIT_EMAIL="${2:-}"
PYTHON_VERSION="${PYTHON_VERSION:-3.14}"   # stable release line
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

step() { printf '\n\033[36m==> %s\033[0m\n' "$1"; }

# --- 1. Core tools -----------------------------------------------------------
step "Installing core tools"
case "$(uname -s)" in
  Darwin)
    if ! command -v brew >/dev/null; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
    fi
    brew install git bash node gh
    command -v code >/dev/null || brew install --cask visual-studio-code
    ;;
  Linux)
    if command -v apt-get >/dev/null; then
      sudo apt-get update
      sudo apt-get install -y git curl build-essential gh nodejs npm
    elif command -v dnf >/dev/null; then
      sudo dnf install -y git curl gcc make gh nodejs npm
    else
      echo "Unsupported package manager - install git, curl, node and gh manually." >&2
    fi
    ;;
esac

# --- 2. Python via uv --------------------------------------------------------
step "Installing uv and Python $PYTHON_VERSION"
if ! command -v uv >/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi
uv python install "$PYTHON_VERSION" --default --preview
uv tool install ruff

# --- 3. Git configuration ----------------------------------------------------
step "Configuring Git"
[ -n "$GIT_NAME" ]  && git config --global user.name  "$GIT_NAME"
[ -n "$GIT_EMAIL" ] && git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main
git config --global core.autocrlf input
git config --global pull.rebase false
git config --global core.editor "code --wait"

# --- 4. VS Code extensions ---------------------------------------------------
step "Installing VS Code extensions"
if command -v code >/dev/null; then
  grep -v '^\s*#' "$SCRIPT_DIR/vscode-extensions.txt" | grep -v '^\s*$' | while read -r ext; do
    code --install-extension "$ext" --force
  done
else
  echo "'code' not on PATH. In VS Code: Cmd/Ctrl+Shift+P -> 'Shell Command: Install code command in PATH', then re-run."
fi

# --- 5. Summary --------------------------------------------------------------
step "Installed versions"
git --version
uv run --python "$PYTHON_VERSION" python --version
node --version || true
gh --version | head -1 || true

printf '\n\033[32mDone. Restart your terminal and VS Code. Next: run "gh auth login".\033[0m\n'
