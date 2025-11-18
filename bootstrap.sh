#!/bin/bash
set -eu

REPO_URL=${REPO_URL:-"https://github.com/dkooll/dotfiles-dev.git"}
TARGET_DIR=${TARGET_DIR:-"$HOME/workspaces/dkooll/dotfiles-dev"}

if ! command -v git &> /dev/null || ! command -v zsh &> /dev/null; then
    sudo apt update && sudo apt install -y git zsh
fi

if [ "$SHELL" != "/usr/bin/zsh" ] && [ "$SHELL" != "/bin/zsh" ]; then
    chsh -s "$(which zsh)"
fi

mkdir -p "$(dirname "$TARGET_DIR")"

if [ ! -d "$TARGET_DIR/.git" ]; then
    git clone "$REPO_URL" "$TARGET_DIR"
else
    git -C "$TARGET_DIR" pull --ff-only
fi

"$TARGET_DIR/install.sh"

echo ""
echo "Done! Run 'exec zsh' or logout/login to use zsh"
