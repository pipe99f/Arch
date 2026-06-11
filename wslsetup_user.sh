#!/bin/bash
set -uo pipefail

LOG_FILE="$HOME/arch-setup.log"

if [ -t 1 ]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BOLD='\033[1m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BOLD=''; NC=''
fi

log()    { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG_FILE"; }
info()   { local msg="[INFO]  $*"; echo -e "${GREEN}${msg}${NC}"; log "$msg"; }
warn()   { local msg="[WARN]  $*"; echo -e "${YELLOW}${msg}${NC}"; log "$msg"; }
error()  { local msg="[ERROR] $*"; echo -e "${RED}${msg}${NC}"; log "$msg"; }
step()   { local msg="========  $*  ========"; echo ""; echo -e "${BOLD}${msg}${NC}"; log "$msg"; }

run() {
    local desc="$1"; shift
    step "$desc"
    "$@"
    local rc=$?
    if [ $rc -eq 0 ]; then
        info "$desc — done"
    else
        error "$desc — failed (exit $rc)"
        return $rc
    fi
}

info "Starting wslsetup_user.sh — $(date)"

run "Changing default shell to zsh" chsh -s /usr/bin/zsh

step "Creating directories and files"
touch "$HOME"/.priv
mkdir -p "$HOME"/Downloads/firefox "$HOME"/.config/joplin "$HOME"/.config/joplin-desktop "$HOME"/.config/btop
xdg-user-dirs-update

step "Enabling parallel downloads"
sudo sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

step "Installing WSL packages"
# shellcheck disable=SC2024
sudo pacman --needed -S - <"$HOME"/Arch/packages/wslpackages.txt

step "Installing yay"
if [ -d "$HOME/yay-bin" ]; then
	info "yay-bin directory already exists, skipping clone"
else
	run "Cloning yay" git clone https://aur.archlinux.org/yay-bin.git "$HOME/yay-bin"
fi
(cd "$HOME/yay-bin" && makepkg -si)

step "Installing tmux plugin manager"
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
	info "tpm directory already exists, skipping clone"
else
	run "Cloning tpm" git clone https://github.com/tmux-plugins/tpm "$HOME"/.tmux/plugins/tpm
fi

run "Installing yazi smart-enter plugin" ya pkg add yazi-rs/plugins:smart-enter

step "Installing Catppuccin bat theme"
mkdir -p "$(bat --config-dir)/themes"
wget -P "$(bat --config-dir)/themes" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme
bat cache --build

run "Installing kulala-ls" yarn global add @mistweaverco/kulala-ls

step "Enabling docker"
sudo systemctl enable --now docker.socket
sudo usermod -aG docker "$USER"

run "Enabling reflector timer" sudo systemctl enable reflector.timer

step "Stowing dotfiles"
if [ -d "$HOME/dotfiles" ]; then
	info "dotfiles directory already exists, skipping clone"
else
	run "Cloning dotfiles" git clone https://github.com/pipe99f/dotfiles "$HOME"/dotfiles
fi
(cd "$HOME/dotfiles" && rm -f "$HOME"/.zshrc "$HOME"/.bashrc "$HOME"/.bash_profile "$HOME"/.config/atuin/config.toml "$HOME"/.config/mimeapps.list && stow -- *)

step "Installing pixi packages"
pixi global install --environment data-science-env pynvim jupyter_client plotly kaleido-core python-kaleido pyperclip radian jupyterlab jupyter_console

info "wslsetup_user.sh completed — $(date)"