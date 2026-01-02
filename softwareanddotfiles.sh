#!/bin/bash

chsh -s /usr/bin/zsh

echo "Is this a laptop?"
select yn in "Yes" "No"; do
	case $yn in
	Yes)
		sudo pacman -S acpi acpi_call tlp bluez bluez-utils brightnessctl wireless_tools
		systemctl enable bluetooth.service
		systemctl enable tlp
		break
		;;
	No) break ;;
	esac
done

#Hook that deletes pacman cache
# mkdir /etc/pacman.d/hooks && touch /etc/pacman.d/clean_pacman_cache.hook
# tee -a /etc/pacman.d/hooks/clean_pacman_cache.hook << END
# [Trigger]
# Operation = Upgrade
# Operation = Install
# Operation = Remove
# Type = Package
# Target = *
# [Action]
# Description = Cleaning pacman cache...
# When = PostTransaction
# Exec = /usr/bin/paccache -r
# END

# Some empty directories and files that I prefer to create now
echo "Creating directories and files..."
touch "$HOME"/.priv
mkdir -p "$HOME"/Downloads/firefox "$HOME"/.config/joplin "$HOME"/.config/joplin-desktop "$HOME"/.config/btop
xdg-user-dirs-update

#enabling multilib
echo "Enabling multilib"
echo '[multilib]' | sudo tee -a /etc/pacman.conf
echo 'Include = /etc/pacman.d/mirrorlist' | sudo tee -a /etc/pacman.conf

# chaotic-aur
echo "Enabling chaotic-aur"
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
echo '[chaotic-aur]' | sudo tee -a /etc/pacman.conf
echo 'Include = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
sudo pacman -Sy

#enable parallel downloads
sudo sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

#install basic packages
sudo pacman --needed -S - <"$HOME"/Arch/packages/basicpacman.txt

#install fonts
# mkdir -p "$HOME"/.fonts/
# cd "$HOME"/.fonts/
# wget -P "$HOME"/.fonts/ "$(curl -L -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep -o -E "https(.*)Arimo(.*).tar.xz")"
# wget -P "$HOME"/.fonts/ "$(curl -L -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep -o -E "https(.*)RobotoMono(.*).tar.xz")"

#YAY installation. NINGUN PAQUETE AUR QUEDÓ INSTALADO CORRECTAMENTE
echo "Installing yay..."
git clone https://aur.archlinux.org/yay-bin.git "$HOME"/yay-bin
cd "$HOME"/yay-bin
makepkg -si

#tmux plugin manager
echo "Cloning tmux plugin manager..."
git clone https://github.com/tmux-plugins/tpm "$HOME"/.tmux/plugins/tpm

#custom .desktop
echo "Creating custom .desktop files..."
mkdir "$HOME"/.local/share/applications
touch "$HOME"/.local/share/applications/steamgamemode.desktop
tee -a "$HOME"/.local/share/applications/steamgamemode.desktop <<END
[Desktop Entry]
Name=Steam gamemode
Comment= Gamemode
Exec=gamemoderun steam-runtime
Icon=steam
Terminal=false
Type=Application
Categories=Game;
END

#default applications
# handlr set inode/directory thunar.desktop
# handlr set application/pdf org.pwmt.zathura.desktop
#

# yazi plugins
ya pkg add yazi-rs/plugins:smart-enter

# bat theme
mkdir -p "$(bat --config-dir)/themes"
wget -P "$(bat --config-dir)/themes" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme
bat cache --build

#Stow
echo "Stowing..."
git clone https://github.com/pipe99f/dotfiles "$HOME"/dotfiles
cd "$HOME"/dotfiles
rm "$HOME"/.zshrc "$HOME"/.bashrc "$HOME"/.bash_profile "$HOME"/.config/atuin/config.toml "$HOME"/.config/mimeapps.list
stow *

# Install necessary pixi packages
pixi global install --environment data-science-env pynvim jupyter_client plotly kaleido-core python-kaleido pyperclip radian jupyterlab jupyter_console

# Dependency for molten nvim
luarocks --local --lua-version=5.1 install magick
#luarocks --local install magick

# Doom emacs
#git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
#~/.config/emacs/bin/doom install
#doom sync
#rm -r "$HOME"/.emacs.d "$HOME"/.emacs

#enable services
echo "Enabling services..."
systemctl --user enable --now pipewire.socket
systemctl --user enable --now pipewire-pulse.socket
systemctl --user enable --now wireplumber.service
systemctl enable paccache.timer
systemctl enable ufw.service
systemctl enable archlinux-keyring-wkd-sync.timer
systemctl enable cups.service
systemctl enable cronie.service
systemctl enable pkgfile-update.timer
#si se usa ssd
systemctl enable fstrim.timer
systemctl enable grub-btrfsd
