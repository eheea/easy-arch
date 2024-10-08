#!/bin/bash
echo "please insert disk name (eg; sda,sdb)"
read -r disk
#creating a GPT partition table with 2 partitions for boot and root
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
mkfs.fat -F32 /dev/"$disk"1
mkfs.ext4 -F /dev/"$disk"2

#mounting the disks
mount /dev/"$disk"2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/"$disk"1 /mnt/boot/efi

#installing the base system
pacstrap -K /mnt base base-devel linux linux-firmware grub efibootmgr networkmanager nano neofetch

#generating fstab
genfstab -U /mnt >> /mnt/etc/fstab

#going into the newly installed system
arch-chroot /mnt

#system configs
ln -sf /usr/share/zoneinfo/Asia/Baghdad /etc/localtime
