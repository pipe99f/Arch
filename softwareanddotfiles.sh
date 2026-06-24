#!/bin/bash
set -uo pipefail

LOG_FILE="$HOME/arch-setup.log"

if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BOLD=''
    NC=''
fi

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >>"$LOG_FILE"; }
info() {
    local msg="[INFO]  $*"
    echo -e "${GREEN}${msg}${NC}"
    log "$msg"
}
warn() {
    local msg="[WARN]  $*"
    echo -e "${YELLOW}${msg}${NC}"
    log "$msg"
}
error() {
    local msg="[ERROR] $*"
    echo -e "${RED}${msg}${NC}"
    log "$msg"
}
step() {
    local msg="========  $*  ========"
    echo ""
    echo -e "${BOLD}${msg}${NC}"
    log "$msg"
}

run() {
    local desc="$1"
    shift
    step "$desc"
    "$@"
    local rc=$?
    if [ "$rc" -eq 0 ]; then
        info "$desc — done"
    else
        error "$desc — failed (exit $rc)"
        return "$rc"
    fi
}

info "Starting softwareanddotfiles.sh — $(date)"

run "Changing default shell to zsh" chsh -s /usr/bin/zsh

step "Laptop configuration"
echo "Is this a laptop?"
select yn in "Yes" "No"; do
    case $yn in
    Yes)
        sudo pacman -S acpi acpi_call tlp bluez bluez-utils brightnessctl wireless_tools
        sudo systemctl enable bluetooth.service
        sudo systemctl enable tlp
        break
        ;;
    No) break ;;
    esac
done

step "Creating directories and files"
touch "$HOME"/.priv
mkdir -p "$HOME"/Downloads/firefox "$HOME"/.config/joplin "$HOME"/.config/joplin-desktop "$HOME"/.config/btop
xdg-user-dirs-update

step "Enabling multilib"
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    echo '[multilib]' | sudo tee -a /etc/pacman.conf
    echo 'Include = /etc/pacman.d/mirrorlist' | sudo tee -a /etc/pacman.conf
    info "multilib repository enabled"
else
    info "multilib repository already enabled, skipping"
fi

step "Enabling chaotic-aur"
run "Receiving chaotic-aur key" sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
run "Signing chaotic-aur key" sudo pacman-key --lsign-key 3056513887B78AEB
run "Installing chaotic-aur keyring" sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
run "Installing chaotic-aur mirrorlist" sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
if ! grep -q '^\[chaotic-aur\]' /etc/pacman.conf; then
    echo '[chaotic-aur]' | sudo tee -a /etc/pacman.conf
    echo 'Include = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
    info "chaotic-aur repository enabled"
else
    info "chaotic-aur repository already enabled, skipping"
fi
run "Syncing package databases" sudo pacman -Sy

step "Enabling parallel downloads"
sudo sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

step "Installing basic packages"
# shellcheck disable=SC2024
sudo pacman --needed -S - <"$HOME"/Arch/packages/basicpacman.txt

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

step "Creating Steam gamemode desktop entry"
mkdir -p "$HOME"/.local/share/applications
tee "$HOME"/.local/share/applications/steamgamemode.desktop <<END
[Desktop Entry]
Name=Steam gamemode
Comment= Gamemode
Exec=gamemoderun steam-runtime
Icon=steam
Terminal=false
Type=Application
Categories=Game;
END

run "Installing rust stable toolchain" rustup default stable

run "Installing yazi smart-enter plugin" ya pkg add yazi-rs/plugins:smart-enter

step "Installing Catppuccin bat theme"
mkdir -p "$(bat --config-dir)/themes"
wget -P "$(bat --config-dir)/themes" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme
bat cache --build

run "Installing kulala-ls" yarn global add @mistweaverco/kulala-ls

step "Stowing dotfiles"
if [ -d "$HOME/dotfiles" ]; then
    info "dotfiles directory already exists, skipping clone"
else
    run "Cloning dotfiles" git clone https://github.com/pipe99f/dotfiles "$HOME"/dotfiles
fi
(cd "$HOME/dotfiles" && rm -f "$HOME"/.zshrc "$HOME"/.bashrc "$HOME"/.bash_profile "$HOME"/.config/atuin/config.toml "$HOME"/.config/mimeapps.list "$HOME"/.config/ghostty/config.ghostty && stow -- *)

step "Installing pixi packages"
pixi global install --environment data-science-env pynvim jupyter_client plotly kaleido-core python-kaleido pyperclip radian jupyterlab jupyter_console ipython
# Create a kernel for general use (jupynvim)
"$HOME"/.pixi/envs/data-science-env/bin/python -m ipykernel install --user --name pixi_ds_global

step "Edit pam login for auto keyring authentication after login"
configure_pam_login() {
    local pam_file="/etc/pam.d/login"
    local modified=false

    # Define the exact lines to add
    local auth_line="auth       optional     pam_gnome_keyring.so"
    local session_line="session       optional     pam_gnome_keyring.so auto_start"

    # Check and add the 'auth' line if it doesn't exist
    # [[:space:]]+ accounts for any mixture of tabs or spaces between words
    if ! grep -q '^[[:space:]]*auth[[:space:]]+optional[[:space:]]+pam_gnome_keyring\.so' "$pam_file"; then
        echo "$auth_line" | sudo tee -a "$pam_file" >/dev/null
        modified=true
        info "Added gnome-keyring auth module to $pam_file"
    fi

    # Check and add the 'session' line if it doesn't exist
    if ! grep -q '^[[:space:]]*session[[:space:]]+optional[[:space:]]+pam_gnome_keyring\.so[[:space:]]+auto_start' "$pam_file"; then
        echo "$session_line" | sudo tee -a "$pam_file" >/dev/null
        modified=true
        info "Added gnome-keyring session module to $pam_file"
    fi

    if [ "$modified" = false ]; then
        info "PAM login configuration is already up to date. Skipping."
    fi
}
configure_pam_login

step "Enabling services"
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service
sudo systemctl enable --now ufw.service archlinux-keyring-wkd-sync.timer paccache.timer earlyoom
sudo systemctl enable --now docker.socket
sudo usermod -aG docker "$USER"
sudo systemctl enable --now grub-btrfsd
sudo systemctl enable cups.service cronie.service

info "softwareanddotfiles.sh completed — $(date)"
