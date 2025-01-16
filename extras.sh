#!/bin/bash

# Function to display the main menu
show_menu() {
  # clear
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
  read -p "Enter your choice: " choice
}

# Function to install extra packages
install_extra_packages() {
  echo "Installing extra packages..."
  sudo pacman --needed -S - <"$HOME"/Arch/packages/pacmanpackages.txt
  sudo pacman -S --needed - <"$HOME"/Arch/packages/chaoticaur.txt
  yay -S $(cat "$HOME"/Arch/packages/aurpackages.txt)
}

# Function to install Miniconda (example)
install_miniconda() {
  echo "Installing Miniconda..."
  mkdir -p ~/miniconda3
  wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
  bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
  rm ~/miniconda3/miniconda.sh
}

# Function to config RetroArch
config_retroarch() {
  echo "Configuring RetroArch..."
  cp -rva ./configs/retroarch/ "$HOME"/.config/retroarch/
  mkdir "$HOME"/.config/retroarch/system/pcsx2/cheats "$HOME"/.config/retroarch/system/pcsx2/cheats_ws
}

# Function to create mountpoints
create_mountpoints() {
  echo "Creating mountpoints..."
  sudo mkdir /mnt/ce /mnt/ve /mnt/external
  ln -s /mnt/ce $HOME/ce
  sudo chown -R pipe99f:pipe99f /mnt/ce
  sudo chmod -R 755 /mnt/ce

  ln -s /mnt/ve $HOME/ve
  sudo chown -R pipe99f:pipe99f /mnt/ve
  sudo chmod -R 755 /mnt/ve

  ln -s /mnt/external $HOME/external
  sudo chown -R pipe99f:pipe99f /mnt/external
  sudo chmod -R 755 /mnt/external

  echo "Get UUID's with sudo blkid"
  echo "Complete fstab with the next format"
  echo "UUID=<partition UUID> /mnt/<mountpoint> <either ext4 or ntfs-3g> defaults 0 2"

}

setup_spicetify() {
  echo "Setting up spicetify..."
  spicetify
  spicetify backup apply enable-devtools
  mkdir -p $HOME/.config/spicetify/Themes
  spicetify config inject_css 1
  spicetify config replace_colors 1
  spicetify config current_theme marketplace
  spicetify config custom_apps marketplace
  spicetify apply
  wl-copy <"$HOME"/Arch/configs/spicetify_marketplace_settings
  echo "Settings copied to clipboard, paste in Marketplace > Settings > Back up/Restore"

}

setup_timeshift() {
  echo "Setting up timeshift..."
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
  echo "Setting up atuin..."
  atuin login -u pipe99f
  atuin import auto
  atuin sync
}

setup_git() {
  echo "Setting up git..."
  git config --global user.name "pipe99f"
  git config --global user.email "felipe99al@gmail.com"
  ssh-keygen -t ed25519 -C "felipe99al@gmail.com"
  eval "$(ssh-agent -s)"
  ssh-add $HOME/.ssh/id_ed25519
  cat $HOME/.ssh/id_ed25519.pub
  echo "Copy from the start until the second string (i.e. exclude the email) and paste in github ssh add page"
}

# Function to config everything
config_everything() {
  install_extra_packages
  read -p "Continue to next step? (yes/no): " answer
  if [ "$answer" != "yes" ]; then
    return
  fi

  install_miniconda
  read -p "Continue to next step? (yes/no): " answer
  if [ "$answer" != "yes" ]; then
    return
  fi

  config_retroarch
  read -p "Continue to next step? (yes/no): " answer
  if [ "$answer" != "yes" ]; then
    return
  fi

  create_mountpoints
  read -p "Continue to next step? (yes/no): " answer
  if [ "$answer" != "yes" ]; then
    return
  fi

  setup_spicetify
  read -p "Continue to next step? (yes/no): " answer
  if [ "$answer" != "yes" ]; then
    return
  fi

  setup_timeshift
  read -p "Continue to next step? (yes/no): " answer
  if [ "$answer" != "yes" ]; then
    return
  fi

  setup_atuin
  read -p "Continue to next step? (yes/no): " answer
  if [ "$answer" != "yes" ]; then
    return
  fi

  setup_git
  read -p "Continue to next step? (yes/no): " answer
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
    echo "Exiting..."
    exit 0
    ;;
  *)
    echo "Invalid choice. Please try again."
    ;;
  esac
done
