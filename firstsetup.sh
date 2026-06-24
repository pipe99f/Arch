#!/bin/bash
set -uo pipefail

LOG_FILE="/var/log/arch-setup.log"

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

info "Starting firstsetup.sh — $(date)"

step "Configuring timezone and clock"
ln -sf /usr/share/zoneinfo/America/Bogota /etc/localtime
hwclock --systohc

step "Configuring locale"
sed -i 's/#en_US UTF-8/en_US UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >/etc/locale.conf

step "Configuring hostname and hosts"
echo "arch" >/etc/hostname
cat >/etc/hosts <<EOF
127.0.0.1 localhost
::1       localhost
127.0.1.1 arch.localdomain arch
EOF

step "Setting root password"
set_password() {
  local username="${1:-}"
  while true; do
    if [ "$username" = "" ]; then
      if passwd; then
        info "Password set successfully."
        return 0
      else
        warn "Password setting failed. Please try again."
      fi
    else
      if passwd "$username"; then
        info "Password set successfully."
        return 0
      else
        warn "Password setting failed. Please try again."
      fi
    fi
  done
}
set_password

run "Selecting fastest mirrors" reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

step "Cleaning up"
rm /var/lib/pacman/db.lck

step "Installing base packages"
pacman -S curl grub networkmanager dialog wpa_supplicant mtools dosfstools linux-headers avahi xdg-user-dirs xdg-utils os-prober openssh gvfs pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber efibootmgr ntp acpid nss-mdns iptables dnsmasq openbsd-netcat zsh

step "Installing CPU microcode"
if grep -q "AuthenticAMD" /proc/cpuinfo; then
  run "Installing AMD microcode" pacman -S amd-ucode
elif grep -q "GenuineIntel" /proc/cpuinfo; then
  run "Installing Intel microcode" pacman -S intel-ucode
else
  info "No AMD or Intel CPU detected, skipping microcode"
fi

run "Installing bootloader" grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB || exit 1
run "Generating GRUB config" grub-mkconfig -o /boot/grub/grub.cfg || exit 1

step "Configuring GRUB defaults"
sed -i 's/#GRUB_SAVEDEFAULT=true/GRUB_SAVEDEFAULT=true/' /etc/default/grub
sed -i 's/GRUB_DEFAULT=0/GRUB_DEFAULT=saved/' /etc/default/grub
sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub

run "Enabling system services" systemctl enable NetworkManager sshd.service reflector.timer avahi-daemon ntpd.service acpid

step "Creating user"
while true; do
  read -rp "Enter your username: " username
  read -rp "Please re-enter your username: " username_confirm

  if [ "$username" = "$username_confirm" ]; then
    info "Username confirmed: $username"
    break
  else
    warn "Username verification failed. Please try again."
  fi
done

run "Creating user $username" useradd -m "$username"
step "Setting password for $username"
set_password "$username"
run "Adding $username to wheel group" usermod -aG wheel "$username"

step "Configuring sudo for $username"
if [ ! -f /etc/sudoers.d/"$username" ]; then
  echo "%wheel ALL=(ALL) ALL" >>/etc/sudoers.d/"$username"
  info "Sudoers file created for $username"
else
  info "Sudoers file already exists for $username, skipping"
fi

step "Configuring mkinitcpio for btrfs"
sed -i 's/MODULES=()/MODULES=(btrfs)/' /etc/mkinitcpio.conf
run "Regenerating initramfs" mkinitcpio -P || exit 1

step "Configuring I/O schedulers"
tee /etc/udev/rules.d/60.ioschedulers.rules <<END
# HDD
ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"

# SSD
ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="bfq"

# NVMe SSD
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
END

info "firstsetup.sh completed — $(date)"

