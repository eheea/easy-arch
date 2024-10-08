#!/bin/bash
echo "please insert disk name (eg; sda,sdb)"
read -r disk
fdisk /dev/"$disk"
echo "g"
echo "n"
echo ""
echo ""
echo "+1G"
echo "n"
echo ""
echo ""
echo ""
echo "w"
