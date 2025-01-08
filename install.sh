#!/bin/bash
clear
lsblk
echo "select which disk to erase and install arch linux on (eg; sda,sdb,vda...etc)"
read -r disk
(
echo "g"
echo "n"
echo " "
echo " "
echo "+1G"
echo "n"
echo " "
echo " "
echo "+16G"
echo "n"
echo " "
echo " "
echo " "
echo "w"
) | fdisk /dev/"$disk"

mkfs.fat -F32 /dev/"$disk"1
mkfs.ext4 /dev/"$disk"3
mkswap /dev/"$disk"2

mount /dev/"$disk"3 /mnt
mkdir -p /mnt/boot/efi
mount /dev/"$disk"1 /mnt/boot/efi
swapon /dev/"$disk"2

pacstrap -K /mnt base base-devel linux linux-firmware grub efibootmgr nano neofetch networkmanager networkmanager-openvpn network-manager-applet ntfs-3g dosfstools fuse flatpak clutter
genfstab -U /mnt >> /mnt/etc/fstab
