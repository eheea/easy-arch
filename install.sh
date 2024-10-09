#!/bin/bash
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
arch-chroot /mnt /bin/bash << EOF

#clock config
ln -sf /usr/share/zoneinfo/Asia/Baghdad /etc/localtime
hwclock --systohc

#making swap
mkswap -U clear --size 4G --file /swapfile
swapon /swapfile
echo "/swapfile none swap defaults 0 0"

#locale config
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> locale.conf

#Network Configuration
echo "$host" >> /etc/hostname
systemctl enable NetworkManager

#setting root password
{ echo "$rootpasswd"
echo "$rootpasswd"

} | passwd

#installing grub
mkdir -p /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg
grub-install

#adding a user
useradd -m -G wheel,input,users -s /bin/bash "$username"
{ echo "$userpasswd"
echo "$userpasswd"

} | passwd "$username"

#making the user able to use sudo
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

#enabling multilib
sed -i '92s/^#//' /etc/pacman.conf
sed -i '93s/^#//' /etc/pacman.conf
sudo pacman -Sy
echo "Multilib repository enabled and package database updated."

#installing the AUR helper
if [ ! -f /usr/bin/yay ]; then
sudo pacman -S --noconfirm  --needed git go base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm
else echo "yay is already installed"
fi

EOF

umount -a