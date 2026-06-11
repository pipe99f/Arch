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

info "Starting extras.sh — $(date)"

# Function to display the main menu
show_menu() {
  echo "-------------------------------"
  echo "Arch Linux Extra Configurations"
  echo "-------------------------------"
  echo "1. Install Extra Packages"
  echo "2. Install Miniconda"
  echo "3. Config RetroArch"
  echo "4. Create Mountpoints"
  echo "5. Setup Spicetify"
  echo "6. Setup Timeshift"
  echo "7. Setup Atuin"
  echo "8. Setup Git"
  echo "9. Config Everything"
  echo "0. Exit"
  echo "------------------------------"
  read -rp "Enter your choice: " choice
}

# Function to install extra packages
install_extra_packages() {
  step "Installing extra packages"
  # shellcheck disable=SC2024
  sudo pacman --needed -S - <"$HOME"/Arch/packages/pacmanpackages.txt
# shellcheck disable=SC2024
  sudo pacman -S --needed - <"$HOME"/Arch/packages/chaoticaur.txt
  yay -S --needed - <"$HOME"/Arch/packages/aurpackages.txt
}

# Function to install Miniconda
install_miniconda() {
  step "Installing Miniconda"
  mkdir -p ~/miniconda3
  wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
  bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
  rm ~/miniconda3/miniconda.sh
}

# Function to config RetroArch
config_retroarch() {
  step "Configuring RetroArch"
  cp -rva ./configs/retroarch/ "$HOME"/.config/retroarch/
  mkdir -p "$HOME"/.config/retroarch/system/pcsx2/cheats "$HOME"/.config/retroarch/system/pcsx2/cheats_ws
}

# Function to create mountpoints
create_mountpoints() {
  step "Creating mountpoints"
  sudo mkdir -p /mnt/ce /mnt/ve /mnt/external
  ln -sf /mnt/ce "$HOME"/ce
  sudo chown -R pipe99f:pipe99f /mnt/ce
  sudo chmod -R 755 /mnt/ce

  ln -sf /mnt/ve "$HOME"/ve
  sudo chown -R pipe99f:pipe99f /mnt/ve
  sudo chmod -R 755 /mnt/ve

  ln -sf /mnt/external "$HOME"/external
  sudo chown -R pipe99f:pipe99f /mnt/external
  sudo chmod -R 755 /mnt/external

  info "Get UUID's with sudo blkid"
  info "Complete fstab with the next format:"
  info "UUID=<partition UUID> /mnt/<mountpoint> <either ext4 or ntfs-3g> defaults 0 2"
}

setup_spicetify() {
  step "Setting up spicetify"
  spicetify
  spicetify backup apply enable-devtools
  mkdir -p "$HOME"/.config/spicetify/Themes
  spicetify config inject_css 1
  spicetify config replace_colors 1
  spicetify config current_theme marketplace
  spicetify config custom_apps marketplace
  spicetify apply
  wl-copy <"$HOME"/Arch/configs/spicetify_marketplace_settings.json
  info "Settings copied to clipboard, paste in Marketplace > Settings > Back up/Restore"
}

setup_timeshift() {
  step "Setting up timeshift"
  sudo timeshift --scripted
  sudo sed -i 's@"schedule_weekly" : "false",@"schedule_weekly" : "true",@' /etc/timeshift/timeshift.json
  sudo sed -i 's@"schedule_daily" : "false",@"schedule_daily" : "true",@' /etc/timeshift/timeshift.json
  sudo sed -i 's@"count_weekly" : "3",@"count_weekly" : "2",@' /etc/timeshift/timeshift.json
  sudo sed -i 's@"count_daily" : "5",@"count_daily" : "2",@' /etc/timeshift/timeshift.json

  sudo systemctl enable grub-btrfsd
  sudo sed -i 's@/.snapshots@--timeshift-auto@' /etc/systemd/system/grub-btrfsd.service
  sudo systemctl restart grub-btrfsd
  sudo grub-mkconfig
  sudo grub-install --efi-directory=/boot
}

setup_atuin() {
  step "Setting up atuin"
  atuin login -u pipe99f
  atuin import auto
  atuin sync
}

setup_git() {
  step "Setting up git"
  git config --global user.name "pipe99f"
  git config --global user.email "felipe99al@gmail.com"
  ssh-keygen -t ed25519 -C "felipe99al@gmail.com"
  eval "$(ssh-agent -s)"
  ssh-add "$HOME"/.ssh/id_ed25519
  cat "$HOME"/.ssh/id_ed25519.pub
  info "Copy from the start until the second string (i.e. exclude the email) and paste in github ssh add page"
}

# Function to config everything
config_everything() {
  install_extra_packages
  read -rp "Continue to next step? (yes/no): " answer
  if [ "$answer" != "yes" ]; then
    return
  fi

  install_miniconda
  read -rp "Continue to next step? (yes/no): " answer
  if [ "$answer" != "yes" ]; then
    return
  fi

  config_retroarch
  read -rp "Continue to next step? (yes/no): " answer
  if [ "$answer" != "yes" ]; then
    return
  fi

  create_mountpoints
  read -rp "Continue to next step? (yes/no): " answer
  if [ "$answer" != "yes" ]; then
    return
  fi

  setup_spicetify
  read -rp "Continue to next step? (yes/no): " answer
  if [ "$answer" != "yes" ]; then
    return
  fi

  setup_timeshift
  read -rp "Continue to next step? (yes/no): " answer
  if [ "$answer" != "yes" ]; then
    return
  fi

  setup_atuin
  read -rp "Continue to next step? (yes/no): " answer
  if [ "$answer" != "yes" ]; then
    return
  fi

  setup_git
  read -rp "Continue to next step? (yes/no): " answer
  if [ "$answer" != "yes" ]; then
    return
  fi
}

# Main loop
while true; do
  show_menu
  case "$choice" in
  1)
    install_extra_packages
    ;;
  2)
    install_miniconda
    ;;
  3)
    config_retroarch
    ;;
  4)
    create_mountpoints
    ;;
  5)
    setup_spicetify
    ;;
  6)
    setup_timeshift
    ;;
  7)
    setup_atuin
    ;;
  8)
    setup_git
    ;;
  9)
    config_everything
    ;;
  0)
    info "Exiting..."
    exit 0
    ;;
  *)
    warn "Invalid choice. Please try again."
    ;;
  esac
done