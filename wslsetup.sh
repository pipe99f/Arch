#!/bin/bash
set -uo pipefail

LOG_FILE="/var/log/arch-setup.log"

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

info "Starting wslsetup.sh — $(date)"

step "Configuring timezone and locale"
ln -sf /usr/share/zoneinfo/America/Bogota /etc/localtime
sed -i 's/#en_US UTF-8/en_US UTF-8/' /etc/locale.gen
locale-gen
localectl set-locale LANG=en_US.UTF-8

step "Installing WSL packages"
pacman -S nvim zsh base-devel curl xdg-utils xdg-user-dirs reflector

step "Setting root password"
set_password() {
	local username="${1:-}"
	while true; do
		if [ -z "$username" ]; then
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

run "Selecting fastest mirrors" reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

step "Cleaning up"
rm /var/lib/pacman/db.lck

info "wslsetup.sh completed — $(date)"
info "Switch from root to new user (reboot) and run wslsetup_user.sh"