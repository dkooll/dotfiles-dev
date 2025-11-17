#!/bin/sh
set -eu

TARGET_DIR=${TARGET_DIR:-"$HOME/workspaces/dkooll/dotfiles-dev"}
NVIM_CONFIG="$HOME/.config/nvim"

echo "Removing Neovim state..."
rm -rf "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"

echo "Removing Neovim config symlink..."
rm -f "$NVIM_CONFIG"

if [ -d "$TARGET_DIR/nvim" ]; then
    mkdir -p "$(dirname "$NVIM_CONFIG")"
    ln -sf "$TARGET_DIR/nvim" "$NVIM_CONFIG"
    echo "Re-linked $NVIM_CONFIG -> $TARGET_DIR/nvim"
else
    echo "Skipped relink: $TARGET_DIR/nvim not found"
fi
