# dotfiles

Somethimes you want to get your stuff set up fast. Use the bootstrap to clone, install, and link everything in one go:

`
  curl -fsSL https://raw.githubusercontent.com/dkooll/dotfiles-dev/main/bootstrap.sh |
    sed 's|exec "$TARGET_DIR/install.sh"|ANSIBLE_STDOUT_CALLBACK=debug PS4= bash -x "$TARGET_DIR/install.sh"|' |
    bash
`

## Requirements

Install git and zsh yourself first: `sudo apt-get install git zsh`

Switch your login shell to zsh: `chsh -s /usr/bin/zsh`
