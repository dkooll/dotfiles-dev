#!/bin/bash
set -eu

TARGET_DIR="${TARGET_DIR:-$HOME/workspaces/dkooll/dotfiles-dev}"
APT_UPDATED=false

log() { printf "%s\n" "$*"; }

apt_update() {
    [[ "$APT_UPDATED" == true ]] && return
    sudo apt-get update -qq
    APT_UPDATED=true
}

install_pkg() {
    local pkg=$1 bin=${2:-$1}
    command -v "$bin" &>/dev/null && return
    apt_update
    sudo apt-get install -y -qq "$pkg" 2>/dev/null || sudo apt-get install -y -qq -t bookworm-backports "$pkg" 2>/dev/null || true
}

install_source() {
    local name=$1 check=$2 cmd=$3
    eval "$check" &>/dev/null && log "$name already installed" && return
    log "installing $name"
    eval "$cmd"
}

setup_repos() {
    sudo apt-get install -y -qq apt-transport-https ca-certificates curl gnupg lsb-release

    [[ -f /etc/apt/sources.list.d/nodesource.list ]] || {
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/nodesource.gpg && \
        echo 'deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main' | sudo tee /etc/apt/sources.list.d/nodesource.list >/dev/null && \
        APT_UPDATED=false
    } || log "warning: failed to add nodesource repo"

    [[ -f /etc/apt/keyrings/githubcli-archive-keyring.gpg ]] || {
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
        sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        APT_UPDATED=false
    }

    [[ -f /etc/apt/keyrings/microsoft.gpg ]] || {
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg >/dev/null
        sudo chmod go+r /etc/apt/keyrings/microsoft.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ bookworm main" | sudo tee /etc/apt/sources.list.d/azure-cli.list >/dev/null
        APT_UPDATED=false
    }

    grep -q bookworm-backports /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null || {
        echo 'deb http://deb.debian.org/debian bookworm-backports main contrib non-free' | sudo tee /etc/apt/sources.list.d/backports.list >/dev/null
        APT_UPDATED=false
    }
}

install_packages() {
    sudo apt-get install -y -qq build-essential cmake gcc g++ curl wget unzip git

    install_pkg nodejs node
    install_pkg tmux
    install_pkg ripgrep rg
    install_pkg fd-find fdfind
    install_pkg fzf
    install_pkg gh
    install_pkg python3
    install_pkg python3-pip
    install_pkg ansible
    install_pkg azure-cli az

    install_source "neovim" "command -v nvim" \
        "wget -q https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz -O /tmp/nvim.tar.gz && sudo tar -xzf /tmp/nvim.tar.gz -C /opt && sudo ln -sf /opt/nvim-linux-arm64/bin/nvim /usr/local/bin/nvim && rm /tmp/nvim.tar.gz"

    install_source "eza" "command -v eza" \
        "wget -q https://github.com/eza-community/eza/releases/latest/download/eza_\$(uname -m)-unknown-linux-gnu.tar.gz -O /tmp/eza.tar.gz && tar -xzf /tmp/eza.tar.gz -C /tmp && sudo mv /tmp/eza /usr/local/bin/ && rm /tmp/eza.tar.gz"

    install_source "tfenv" "test -d \$HOME/.tfenv" \
        "git clone --depth=1 https://github.com/tfutils/tfenv.git \$HOME/.tfenv && mkdir -p \$HOME/.local/bin && ln -sf \$HOME/.tfenv/bin/tfenv \$HOME/.local/bin/tfenv && ln -sf \$HOME/.tfenv/bin/terraform \$HOME/.local/bin/terraform"

    if [[ -f "$HOME/.local/bin/tfenv" ]]; then
        if ! "$HOME/.local/bin/tfenv" list 2>/dev/null | grep -qE '^[0-9]'; then
            log "installing terraform via tfenv"
            "$HOME/.local/bin/tfenv" install latest
            "$HOME/.local/bin/tfenv" use latest
        fi
    fi

    local go_arch
    case "$(uname -m)" in
        x86_64|amd64) go_arch=amd64 ;;
        arm64|aarch64) go_arch=arm64 ;;
        *) go_arch=amd64 ;;
    esac

    install_source "go" "test -d /usr/local/go" \
        "wget -q https://go.dev/dl/\$(curl -s https://go.dev/VERSION?m=text | head -n1).linux-${go_arch}.tar.gz -O /tmp/go.tar.gz && sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go.tar.gz && rm /tmp/go.tar.gz"

    [[ -x /usr/local/go/bin/go ]] && sudo ln -sf /usr/local/go/bin/go /usr/local/bin/go

    install_source "rust" "command -v rustc" \
        "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable"

    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

    if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi

    if command -v npm &>/dev/null; then
        sudo npm install -g --silent neovim @anthropic-ai/claude-code @openai/codex || true
    fi

    local zsh_path
    zsh_path=$(command -v zsh || true)
    if [[ -n "$zsh_path" ]] && ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi
}

setup_symlinks() {
    mkdir -p "$HOME/.config"

    for pair in ".zshrc:.zshrc" ".tmux.conf:.tmux.conf" "nvim:.config/nvim" "ansible.cfg:.ansible.cfg"; do
        src="$TARGET_DIR/${pair%%:*}"
        dest="$HOME/${pair##*:}"
        [[ ! -e "$src" ]] && continue
        mkdir -p "$(dirname "$dest")"
        [[ -e "$dest" && ! -L "$dest" ]] && mv "$dest" "$dest.backup"
        ln -sf "$src" "$dest"
    done
}

setup_tmux() {
    [[ -d "$HOME/.tmux/plugins/tpm" ]] || git clone -q https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
}

main() {
    setup_repos
    apt_update
    install_packages
    setup_tmux
    setup_symlinks
    log "done"
}

main
