#!/bin/sh
set -eu

REPO_URL=${REPO_URL:-"https://github.com/dkooll/dotfiles-dev.git"}
TARGET_DIR=${TARGET_DIR:-"$HOME/workspaces/dkooll/dotfiles-dev"}

mkdir -p "$(dirname "$TARGET_DIR")"

if [ ! -d "$TARGET_DIR/.git" ]; then
    git clone "$REPO_URL" "$TARGET_DIR"
else
    git -C "$TARGET_DIR" pull --ff-only
fi

exec "$TARGET_DIR/install.sh"
