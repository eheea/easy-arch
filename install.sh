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
mkdir -p /mnt/boot/efi
mount /dev/"$disk"1 /mnt/boot/efi
mount /dev/"$disk"2 /mnt