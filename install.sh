#!/bin/bash
echo "welcome to the auto arch installer"
echo "please select the disk you wish to install archlinux on (eg.. sda.sdb.vda.)"
lsblk
read -r "disk"
clear

echo "do you want a /home partition? (can be useful for disk extension and backups)"
echo "1) yes"
echo "2) no"

read -r "home_agree"
case $home_agree in
1) home_stats=yes ;;
2) clear ;;
*) echo "please enter a valid value"
exit 2 ;;
esac
clear

if [ "$home_stats" = "yes" ] ; then
echo "enter the size of the root partition (40-100GB is recommened, the rest of the disk space will be used on the /home)"
read -r "root_space"
else clear
fi

echo "select the desktop environemt"
echo "1) KDE"
echo "2) gnome"
echo "3) cinnamon"
echo "4) xfce"
echo "5) lxqt"
echo "6) mate"
echo "7) no desktop"

read -r "desktop"
case "$desktop" in
1) desktop_env=plasma-meta ;;
2) desktop_env=gnome ;;
3) desktop_env=cinnamon ;;
4) desktop_env=xfce4 xfce4-goodies ;;
5) desktop_env=lxqt ;;
6) desktop_env=mate ;;
7) echo "no desktop will be installed" ;;
8) echo "invalid option. please run the script again using (./install.sh)"
exit 1
;;
esac

clear

echo "select the login manager. (despite it saying its for gnome or kde they work on everything just pick what you like)"
echo "1) SDDM (for KDE)"
echo "2) GDM (for GNOME)"

read -r "login"
case $login in
1) LM=sddm ;;
2) LM=gdm ;;
esac

clear

echo "enter username"
read -r "username"

echo "enter user password"
read -r -s "userpasswd"

echo "enter the computer's name"
read -r "hostname"

echo "enter root password (if you just press enter root account will be disabled)"
read -r -s "rootpasswd"

if [ $home_stats = "yes" ]; then
(
echo "g"
echo "n"
echo " "
echo " "
echo "+1G"
echo "n"
echo " "
echo " "
echo "+$root_space"
echo "n"
echo " "
echo " "
echo " "
echo "w"
) | fdisk /dev/"$disk"

mkfs.ext4 /dev/"$disk"3
mkfs.ext4 /dev/"$disk"2
mkfs.fat -F32 /dev/"$disk"1

mount /dev/"$disk"2 /mnt
mkdir -p /mnt/boot/efi
mkdir -p /mnt/home
mount /dev/"$disk"3 /mnt/home
mount /dev/"$disk"1 /mnt/boot/efi

else
(
echo "g"
echo "n"
echo " "
echo " "
echo "+1G"
echo "n"
echo " "
echo " "
echo " "
echo "w"
) | fdisk /dev/"$disk"

mkfs.ext4 /dev/"$disk"2
mkfs.fat -F32 /dev/"$disk"1

mount /dev/"$disk"2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/"$disk"1 /mnt/boot/efi
fi