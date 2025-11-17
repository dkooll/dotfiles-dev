#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$HOME/workspaces/dkooll/dotfiles-dev"

ensure_target_dir() {
    if [ "$SCRIPT_DIR" != "$TARGET_DIR" ]; then
        mkdir -p "$(dirname "$TARGET_DIR")"
        if [ ! -d "$TARGET_DIR" ]; then
            cp -r "$SCRIPT_DIR" "$TARGET_DIR"
        fi
        cd "$TARGET_DIR"
        exec "$TARGET_DIR/install.sh"
    fi
}

DOTFILES_DIR="$TARGET_DIR"

check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        printf "Enter sudo password: "
        sudo -v
    fi
}

add_repo() {
    repo_name=$1
    check_cmd=$2
    add_cmd=$3

    if ! eval "$check_cmd" >/dev/null 2>&1; then
        eval "$add_cmd"
    fi
}

setup_repos() {
    check_sudo

    sudo apt-get update -qq
    sudo apt-get install -y -qq apt-transport-https ca-certificates curl gnupg lsb-release

    if [ ! -f /etc/apt/sources.list.d/nodesource.list ]; then
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/nodesource.gpg
        echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list >/dev/null
        sudo apt-get update -qq
    fi

    add_repo "gh" \
        "test -f /etc/apt/keyrings/githubcli-archive-keyring.gpg" \
        "sudo mkdir -p /etc/apt/keyrings && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && echo 'deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main' | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null"

    add_repo "az" \
        "test -f /etc/apt/keyrings/microsoft.gpg" \
        "sudo mkdir -p /etc/apt/keyrings && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg >/dev/null && sudo chmod go+r /etc/apt/keyrings/microsoft.gpg && echo 'deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ bookworm main' | sudo tee /etc/apt/sources.list.d/azure-cli.list >/dev/null"

    add_repo "backports" \
        "grep -q bookworm-backports /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null" \
        "echo 'deb http://deb.debian.org/debian bookworm-backports main contrib non-free' | sudo tee /etc/apt/sources.list.d/backports.list >/dev/null"

    sudo apt-get update -qq
}

install_pkg() {
    pkg=$1
    if ! command -v "$pkg" >/dev/null 2>&1; then
        sudo apt-get install -y -qq "$pkg" 2>/dev/null || sudo apt-get install -y -qq -t bookworm-backports "$pkg" 2>/dev/null || true
    fi
}

install_from_source() {
    name=$1
    check_cmd=$2
    install_cmd=$3

    if ! eval "$check_cmd" >/dev/null 2>&1; then
        printf "installing %s\n" "$name"
        eval "$install_cmd"
    fi
}

install_packages() {
    check_sudo

    sudo apt-get install -y -qq build-essential cmake gcc g++ git curl wget

    install_pkg zsh
    install_pkg nodejs
    install_pkg tmux
    install_pkg ripgrep
    install_pkg fd-find
    install_pkg fzf
    install_pkg gh
    install_pkg python3
    install_pkg python3-pip
    install_pkg ansible

    install_from_source "neovim" \
        "command -v nvim" \
        "wget -q https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz -O /tmp/nvim.tar.gz && sudo tar -xzf /tmp/nvim.tar.gz -C /opt && sudo ln -sf /opt/nvim-linux-arm64/bin/nvim /usr/local/bin/nvim && rm /tmp/nvim.tar.gz"

    install_from_source "eza" \
        "command -v eza" \
        "wget -q https://github.com/eza-community/eza/releases/latest/download/eza_$(uname -m)-unknown-linux-gnu.tar.gz -O /tmp/eza.tar.gz && tar -xzf /tmp/eza.tar.gz -C /tmp && sudo mv /tmp/eza /usr/local/bin/ && rm /tmp/eza.tar.gz"

    install_from_source "tfenv" \
        "test -d $HOME/.tfenv" \
        "git clone --depth=1 https://github.com/tfutils/tfenv.git $HOME/.tfenv && mkdir -p $HOME/.local/bin && ln -sf $HOME/.tfenv/bin/tfenv $HOME/.local/bin/tfenv && ln -sf $HOME/.tfenv/bin/terraform $HOME/.local/bin/terraform"

    install_from_source "go" \
        "test -d /usr/local/go" \
        "wget -q https://go.dev/dl/\$(curl -s https://go.dev/VERSION?m=text | head -n1).linux-arm64.tar.gz -O /tmp/go.tar.gz && sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go.tar.gz && rm /tmp/go.tar.gz"

    install_from_source "rust" \
        "command -v rustc" \
        "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable && . $HOME/.cargo/env"

    if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env"
    fi

    if ! command -v az >/dev/null 2>&1; then
        printf "installing azure-cli\n"
        pip3 install --user azure-cli --break-system-packages
    fi

    if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi

    if command -v npm >/dev/null 2>&1; then
        sudo npm install -g neovim || true
        sudo npm install -g @anthropic-ai/claude-code || true
        sudo npm install -g @openai/codex || true
    fi

    if [ "$SHELL" != "$(command -v zsh)" ]; then
        chsh -s "$(command -v zsh)" 2>/dev/null || true
    fi
}

setup_tmux() {
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        git clone -q https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    fi
}

create_symlink() {
    src="$DOTFILES_DIR/$1"
    dest="$HOME/$2"

    [ ! -e "$src" ] && return

    mkdir -p "$(dirname "$dest")"

    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        mv "$dest" "$dest.backup"
    fi

    ln -sf "$src" "$dest"
}

setup_symlinks() {
    mkdir -p "$HOME/.config"

    create_symlink "zsh/.zshrc" ".zshrc"
    create_symlink "tmux/.tmux.conf" ".tmux.conf"
    create_symlink "nvim" ".config/nvim"
    create_symlink "ansible.cfg" ".ansible.cfg"
}

main() {
    ensure_target_dir
    setup_repos
    install_packages
    setup_tmux
    setup_symlinks
    printf "done\n"
}

main
