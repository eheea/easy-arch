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
