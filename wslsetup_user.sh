#!/bin/bash

chsh -s /usr/bin/zsh

echo "Creating directories and files..."
touch "$HOME"/.priv
mkdir -p "$HOME"/Downloads/firefox "$HOME"/.config/joplin "$HOME"/.config/joplin-desktop "$HOME"/.config/btop
xdg-user-dirs-update

# enable parallel downloads
sudo sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

sudo pacman --needed -S - <"$HOME"/Arch/packages/wslpackages.txt

echo "Installing yay..."
git clone https://aur.archlinux.org/yay-bin.git "$HOME"/yay-bin
cd "$HOME"/yay-bin
makepkg -si

# tmux plugin manager
echo "Cloning tmux plugin manager..."
git clone https://github.com/tmux-plugins/tpm "$HOME"/.tmux/plugins/tpm

# yazi plugins
ya pkg add yazi-rs/plugins:smart-enter

# bat theme
mkdir -p "$(bat --config-dir)/themes"
wget -P "$(bat --config-dir)/themes" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme
bat cache --build

# Stow
echo "Stowing..."
git clone https://github.com/pipe99f/dotfiles "$HOME"/dotfiles
cd "$HOME"/dotfiles
rm "$HOME"/.zshrc "$HOME"/.bashrc "$HOME"/.bash_profile "$HOME"/.config/atuin/config.toml "$HOME"/.config/mimeapps.list
stow *

# Dependency for molten nvim
luarocks --local --lua-version=5.1 install magick

# Install necessary pixi packages
pixi global install --environment data-science-env pynvim jupyter_client plotly kaleido-core python-kaleido pyperclip radian jupyterlab jupyter_console
