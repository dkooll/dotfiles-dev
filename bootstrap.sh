#!/bin/bash
set -eu

REPO_URL="https://github.com/dkooll/dotfiles-dev.git"
TARGET_DIR="$HOME/workspaces/dkooll/dotfiles-dev"

sudo -v
sudo timedatectl set-ntp true 2>/dev/null || true

if ! command -v git &>/dev/null || ! command -v zsh &>/dev/null; then
    sudo apt update && sudo apt install -y git zsh
fi
[[ "$SHELL" == *zsh ]] || sudo chsh -s "$(which zsh)" "$USER"

mkdir -p "$(dirname "$TARGET_DIR")"
[[ -d "$TARGET_DIR/.git" ]] && git -C "$TARGET_DIR" pull --ff-only || git clone "$REPO_URL" "$TARGET_DIR"

"$TARGET_DIR/install.sh"

echo -e "\nDone! Run 'exec zsh' to reload shell"
