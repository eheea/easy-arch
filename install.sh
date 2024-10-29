#!/bin/bash
clear
echo -e "\e[32mdo you want a separate /home type install (basically separating the home folder on another partition or disk for backup purposes)\e[0m"
echo "1-yes"
echo "2-no"
read -r hi
case $hi in
1) 
clear
lsblk
echo "please insert disk name (eg; sda,sdb)"
read -r disk
echo "        "

echo "insert the user name"
read -r username
echo "        "

echo "insert the host name"
read -r host
echo "     "

echo "please insert your root password"
read -r rootpasswd
echo "        "

echo "please insert your user password"
read -r userpasswd
echo "     "

echo "do you already have a /home that you wish to mount? (yes/no)"
read -r answer

case $answer in
no)
echo "enter the size of the root partition (eg; 80G)"
read -r rootfs
unmount -a
{ echo "g"
  echo "n"
  echo ""
  echo ""
  echo "+1G"
  echo "n"
  echo ""
  echo ""
  echo "+$rootfs"
  echo "n"
  echo " "
  echo " "
  echo " "
  echo "w" 
} | fdisk /dev/"$disk"

#formatting the disks
mkfs.ext4 -F /dev/"$disk"2
mkfs.fat -F32 /dev/"$disk"1
mkfs.ext4 -F /dev/"$disk"3

#mounting the disks
mount /dev/"$disk"2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/"$disk"1 /mnt/boot/efi
mkdir -p /mnt/home
mount /dev/"$disk"3 /mnt/home 
;;
yes) lsblk
echo "select the disk you wish to be /home (eg; sda1,sdb2)"
read -r home2

unmount -a
{ echo "g"
  echo "n"
  echo ""
  echo ""
  echo "+1G"
  echo "n"
  echo ""
  echo ""
  echo ""
  echo "w" 
} | fdisk /dev/"$disk"

#formatting the disks
mkfs.ext4 -F /dev/"$disk"2
mkfs.fat -F32 /dev/"$disk"1

#mounting the disks
mount /dev/"$disk"2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/"$disk"1 /mnt/boot/efi
mkdir -p /mnt/home
mount /dev/"$home2" /mnt/home ;;
*) echo "you didnt enter an appropriate answer" ;;
esac


#installing the base system
pacstrap -K /mnt base base-devel linux linux-firmware grub efibootmgr networkmanager nano neofetch

#generating fstab
genfstab -U /mnt >> /mnt/etc/fstab
echo "fstab was generated successfully"

#going into the newly installed system
arch-chroot /mnt << EOF
ln -sf /usr/share/zoneinfo/Asia/Baghdad /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "$host" >> /etc/hostname
mkswap -U clear --size 4G --file /swapfile
swapon /swapfile
echo "/swapfile none swap default 0 0" >> /etc/fstab
{
echo "$rootpasswd"
echo "$rootpasswd"
} | passwd
useradd -m -G wheel,input -s /bin/bash $username
{
echo "$userpasswd"
echo "$userpasswd"
} | passwd $username
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
systemctl enable NetworkManager
mkdir -p /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg
grub-install
echo "     " >> /etc/pacman.conf
echo "[multilib]" >> /etc/pacman.conf
echo " Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
pacman -Sy
su eheea
mkdir /home/eheea/test
cd /home/eheea/test
sudo rm -rf /home/$username/test/yay
sudo pacman -Sy --noconfirm git go
sudo pacman -S --needed --noconfirm git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm
exit
EOF
echo "system was successfully installed.. rebooting"
sleep 1
umount -a
reboot
;;





2)
clear
lsblk
echo "please insert disk name (eg; sda,sdb)"
read -r disk
echo "        "


echo "insert the user name"
read -r username
echo "        "

echo "insert the host name"
read -r host
echo "     "

echo "please insert your root password"
read -r rootpasswd
echo "        "

echo "please insert your user password"
read -r userpasswd
echo "     "

#making partitions for gpt
umount -a
{ echo "g"
  echo "n"
  echo ""
  echo ""
  echo "+1G"
  echo "n"
  echo ""
  echo ""
  echo ""
  echo "w" 
} | fdisk /dev/"$disk"

#formatting the disks
mkfs.ext4 -F /dev/"$disk"2
mkfs.fat -F32 /dev/"$disk"1

#mounting the disks
mount /dev/"$disk"2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/"$disk"1 /mnt/boot/efi

#installing the base system
pacstrap -K /mnt base base-devel linux linux-firmware grub efibootmgr networkmanager nano neofetch

#generating fstab
genfstab -U /mnt >> /mnt/etc/fstab
echo "fstab was generated successfully"

#going into the newly installed system
arch-chroot /mnt << EOF
ln -sf /usr/share/zoneinfo/Asia/Baghdad /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "$host" >> /etc/hostname
mkswap -U clear --size 4G --file /swapfile
swapon /swapfile
echo "/swapfile none swap default 0 0" >> /etc/fstab
{
echo "$rootpasswd"
echo "$rootpasswd"
} | passwd
useradd -m -G wheel,input -s /bin/bash $username
{
echo "$userpasswd"
echo "$userpasswd"
} | passwd $username
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
systemctl enable NetworkManager
mkdir -p /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg
grub-install
echo "     " >> /etc/pacman.conf
echo "[multilib]" >> /etc/pacman.conf
echo " Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
pacman -Sy
su eheea
mkdir /home/eheea/test
cd /home/eheea/test
sudo rm -rf /home/$username/test/yay
sudo pacman -S --needed --noconfirm git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm
exit
EOF
umount -a
echo "system was successfully installed.. rebooting"
sleep 1
reboot ;;
esac