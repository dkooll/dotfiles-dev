#!/bin/sh
set -eu

echo "Updating apt packages..."
sudo apt-get update -qq
sudo apt-get upgrade -y -qq
sudo apt-get install -y -qq azure-cli || true
sudo apt-get autoremove -y -qq

echo "Updating global npm packages (best effort)..."
if command -v npm >/dev/null 2>&1; then
    sudo npm update -g || true
fi

echo "Updating user pip3 packages..."
if command -v pip3 >/dev/null 2>&1; then
    pip3 install --user --upgrade pip
    outdated=$(pip3 list --user --outdated --format=freeze | cut -d= -f1)
    if [ -n "$outdated" ]; then
        echo "$outdated" | xargs -r pip3 install --user --upgrade
    fi
fi

echo "Updating rust toolchain..."
if command -v rustup >/dev/null 2>&1; then
    rustup update
fi

echo "Updating tfenv + terraform (latest)..."
if command -v tfenv >/dev/null 2>&1; then
    latest_tf="$(tfenv list-remote | head -n1 || true)"
    if [ -n "$latest_tf" ]; then
        tfenv install "$latest_tf" >/dev/null
        tfenv use "$latest_tf" >/dev/null
    fi
fi

echo "Updating Go toolchain (latest)..."
if command -v curl >/dev/null 2>&1; then
    arch=$(uname -m)
    latest_go=$(curl -s https://go.dev/VERSION?m=text | head -n1 || true)
    if [ -n "$latest_go" ]; then
        tmp=/tmp/go.tar.gz
        curl -sL "https://go.dev/dl/${latest_go}.linux-${arch}.tar.gz" -o "$tmp"
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "$tmp"
        rm -f "$tmp"
    fi
fi

echo "Updating Neovim binary (latest)..."
if command -v curl >/dev/null 2>&1; then
    tmp=/tmp/nvim.tar.gz
    curl -sL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz -o "$tmp"
    sudo tar -xzf "$tmp" -C /opt
    sudo ln -sf /opt/nvim-linux-arm64/bin/nvim /usr/local/bin/nvim
    rm -f "$tmp"
fi

echo "Updating eza binary (latest)..."
if command -v curl >/dev/null 2>&1; then
    arch=$(uname -m)
    tmp=/tmp/eza.tar.gz
    curl -sL "https://github.com/eza-community/eza/releases/latest/download/eza_${arch}-unknown-linux-gnu.tar.gz" -o "$tmp"
    tar -xzf "$tmp" -C /tmp
    sudo mv /tmp/eza /usr/local/bin/eza
    rm -f "$tmp"
fi

echo "Done."
