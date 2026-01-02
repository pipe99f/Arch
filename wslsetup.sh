#!/bin/bash

ln -sf /usr/share/zoneinfo/America/Bogota /etc/localtime
sed -i 's/#en_US UTF-8/en_US UTF-8/' /etc/locale.gen
locale-gen
localectl set-locale LANG=en_US.UTF-8

pacman -S nvim zsh base-devel curl xdg-utils xdg-user-dirs reflector

set_password() {
	local username="$1"
	while true; do

		if [ -z "$username" ]; then
			passwd
		else
			passwd "$username"
		fi

		# Check if the passwd command succeeded
		if [ $? -eq 0 ]; then
			echo "Password set successfully."
			return 0
		else
			echo "Password setting failed. Please try again."
		fi
	done
}

set_password

while true; do
	read -p "Enter your username: " username
	read -p "Please re-enter your username: " username_confirm

	if [ "$username" == "$username_confirm" ]; then
		echo "Username confirmed: $username"
		break
	else
		echo "Username verification failed. Please try again."
	fi
done

useradd -m "$username"
set_password "$username"
usermod -aG wheel "$username"
echo "%wheel ALL=(ALL) ALL" >>/etc/sudoers.d/"$username"

reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
rm /var/lib/pacman/db.lck

echo "Switch from root to new user (reboot) and run wslsetup_user.sh"
