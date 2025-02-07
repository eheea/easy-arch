#!/bin/bash

# Prompt for name and passwords
clear
lsblk
echo " "
echo -e "\033[32mSelect which disk to erase and install Arch Linux on (e.g., sda, sdb, vda...etc)\033[0m"
read -r disk
clear

echo "Enter your username"
read -r name
echo " "

echo "Enter your user password"
read -r userpass
echo " "

echo "Enter the machine's name"
read -r host
echo " "

echo "Enter the root password"
read -r passwd
clear

# Initialize pacman keyring and update
pacman-key --init
pacman -Sy --noconfirm
clear

# Partition the disk
(
echo "g"          # Create a new GPT partition table
echo "n"          # Create a new partition
echo " "          # Accept default partition number (1)
echo " "          # Accept default first sector
echo "+1G"        # Set size for the first partition
echo "n"          # Create another new partition
echo " "          # Accept default partition number (2)
echo " "          # Accept default first sector
echo "+16G"       # Set size for the second partition
echo "n"          # Create another new partition (for root)
echo " "          # Accept default partition number (3)
echo " "          # Accept default first sector
echo " "          # Use remaining space
echo "w"          # Write changes
) | fdisk /dev/"$disk"

# Format the partitions
mkfs.fat -F32 /dev/"$disk"1
mkfs.ext4 -F /dev/"$disk"3
mkswap /dev/"$disk"2

# Mount the partitions
mount /dev/"$disk"3 /mnt
mkdir -p /mnt/boot/efi
mount /dev/"$disk"1 /mnt/boot/efi
swapon /dev/"$disk"2

# Adding the CachyOS repos (only needed inside chroot)
curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz && cd cachyos-repo
./cachyos-repo.sh

# Install the base system
pacstrap /mnt base base-devel linux linux-firmware grub efibootmgr nano neofetch networkmanager networkmanager-openvpn network-manager-applet ntfs-3g dosfstools fuse flatpak clutter

# Generate the fstab
genfstab -U /mnt >> /mnt/etc/fstab
echo "fstab was successfully generated"

# Entering the new installed system
arch-chroot /mnt << EOF
ln -sf /usr/share/zoneinfo/Asia/Baghdad /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "en_US.UTF-8" >> /etc/locale.conf
echo "$host" > /etc/hostname

# Set root password
echo "$passwd" | passwd
# Create a new user
useradd -m -G wheel,input -s /bin/bash "$name"
echo "$userpass" | passwd "$name"

# Enable NetworkManager
systemctl enable NetworkManager

# Install and configure GRUB
mkdir -p /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg
grub-install /dev/$disk

# Allow wheel group users to run sudo without password
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers

# Uncomment necessary lines in pacman.conf
sed -i 's/^#\[multilib\]/\[multilib\]/' /etc/pacman.conf
sed -i 's/^#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/' /etc/pacman.conf

# Re-run CachyOS repo script inside the chroot (this was duplicated earlier)
curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz && cd cachyos-repo
./cachyos-repo.sh
EOF

# Unmount everything and reboot
umount -R /mnt
reboot
