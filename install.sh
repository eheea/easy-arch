#!/bin/bash
#prompts for name and passwords
clear
lsblk
echo " "
echo -e "\033[32mselect which disk to erase and install arch linux on (eg; sda,sdb,vda...etc)\033[0m"
read -r disk
clear
echo "enter your username"
read -r name

echo " "

echo "enter your user password"
read -r userpass

echo " "

echo "enter the machine's name"
read -r host

echo " "

echo "enter the root password"
read -r passwd

clear
pacman-key --init
pacman -Sy
clear

#partitioning disks
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


#formatting disks
mkfs.fat -F32 /dev/"$disk"1
mkfs.ext4 -F /dev/"$disk"3
mkswap /dev/"$disk"2


#mounting disks
mount /dev/"$disk"3 /mnt
mkdir -p /mnt/boot/efi
mount /dev/"$disk"1 /mnt/boot/efi
swapon /dev/"$disk"2


#installing the system
pacstrap -K /mnt base base-devel linux linux-firmware grub efibootmgr nano neofetch networkmanager networkmanager-openvpn network-manager-applet ntfs-3g dosfstools fuse flatpak clutter
genfstab -U /mnt >> /mnt/etc/fstab
echo "fstab was successfully generated"

#entering the new installed system
arch-chroot /mnt << EOF
ln -sf /usr/share/zoneinfo/Asia/Baghdad /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "en_US.UTF-8" >> /etc/locale.conf
echo "$host" >> /etc/hostname
(
echo "$passwd"
echo "$passwd"
) | passwd
useradd -m -G wheel,input -s/bin/bash "$name"
(
echo "$userpass"
echo "$userpass"
) | passwd "$name"

systemctl enable NetowrkManager
mkdir -P /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg
grub-install /dev/"$disk"

echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
sed -i '92 s/^#//' /etc/pacman.conf
sed -i '93 s/^#//' /etc/pacman.conf
pacman -Sy
su eheea
sudo pacman -Sy --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si && rm yay
exit
EOF

umount -a
reboot

