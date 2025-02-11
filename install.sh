#!/bin/bash
clear
# a start to the script asking which disk to install archlinux on
echo -e "\e[32mwelcome to the auto arch installer\e[0m"
echo -e "\e[32mplease select the disk you wish to install archlinux on (eg.. sda.sdb.vda.)\e[0m"
lsblk
echo "    "
read -r "disk"
clear

# asking for a home partition
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

#asking for a desktop environment
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
1) desktop_env=plasma-meta dolphin konsole ;;
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

#asking for a login manager
echo "select the login manager. (despite it saying its for gnome or kde they work on everything just pick what you like)"
echo "1) SDDM (for KDE)"
echo "2) GDM (for GNOME)"
echo "3) no login manager"

read -r "login"
case $login in
1) LM=sddm ;;
2) LM=gdm ;;
3) clear
esac

clear

#asking for information
echo "enter username"
read -r "username"

echo "       "
echo "enter user password"
read -r -s "userpasswd"

echo "       "

echo "enter the computer's name"
read -r "hostname"

echo "       "

echo "enter root password (if you just press enter root account will be disabled)"
read -r -s "rootpasswd"


#disk partitioning
if [ "$home_stats" = "yes" ]; then
umount  /dev/"$disk"1
umount /dev/"$disk"2
umount /dev/"$disk"3

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
umount  /dev/"$disk"1
umount /dev/"$disk"2
umount /dev/"$disk"3

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

#adding cachyos repos
curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz && cd cachyos-repo
./cachyos-repo.sh

sed -i '/^ParallelDownloads = 5/s/^/#/' /etc/pacman.conf

#installing the system
pacstrap -K /mnt base base-devel linux-cachyos linux-firmware grub efibootmgr networkmanager nano fastfetch fuse clutter ntfs-3g dosfstools yay auto-cpufreq heroic-games-launcher mangohud goverlay lutris firefox --noconfirm

#generating fstab
genfstab -U /mnt >> /mnt/etc/fstab

#moving in the newly installed system
arch-chroot /mnt << EOF
ln -sf /usr/share/zoneinfo/Asia/Baghdad /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "$hostname" >> /etc/hostname
(
echo "$rootpasswd"
echo "$rootpasswd"
) | passwd

useradd -m -G wheel,input,audio,video,storage,lp -s /bin/bash $username

(
echo "$userpasswd"
echo "$userpasswd"
) | passwd $username

echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers

mkdir -p /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg
grub-install /dev/$disk

pacman -Sy "$desktop_env" "$LM" --noconfirm
systemctl enable NetworkManager $LM

sed -i 's/#\[multilib\]/[multilib]/g' /etc/pacman.conf
sed -i 's/#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/g' /etc/pacman.conf

su eheea
cd ~
mkdir test
cd test
curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz && cd cachyos-repo
sudo ./cachyos-repo.sh

yay -S cachyos-gaming-meta --noconfirm
exit
exit
EOF

umount -R /mnt
reboot