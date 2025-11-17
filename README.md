# dotfiles

Somethimes you want to get your stuff set up fast. Use the bootstrap to clone, install, and link everything in one go:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/dkooll/dotfiles-dev/main/bootstrap.sh)"
```

Set `TARGET_DIR` if you want a different location, otherwise it defaults to `~/workspaces/dkooll/dotfiles-dev`. The install script handles repos, packages, shells, and Neovim setup without prompting so you can get working quickly.
