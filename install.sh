#!/bin/bash
echo "please insert disk name (eg; sda,sdb)"
read -r disk
echo "        "

echo "insert the user name"
read -r username
echo "        "

echo "please insert your root password"
read -r rootpasswd
echo "        "

echo "please insert your user password"
read -r userpasswd


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

#clock config
ln -sf /usr/share/zoneinfo/Asia/Baghdad /etc/localtime
hwclock --systohc

#locale config
sed -i '171 s/#//g' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> locale.conf

#Network Configuration
echo "arch" >> /etc/hostname
systemctl enable NetworkManager

#setting root password
{ echo "$rootpasswd"
echo "$rootpasswd"

} | passwd

#installing grub
mkdir -p /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg
grub-install /dev/"$disk"

#adding a user
useradd -m -G wheel,input,users -s /bin/bash "$username"
{ echo "$userpasswd"
echo "$userpasswd"

} | passwd "$username"

#making the user able to use sudo
SUDO="/etc/sudoers.d/my_custom_sudoers"
if [ -f "$SUDO" ]; then
    echo "File $SUDO already exists. Exiting."
    exit 1
fi

echo "$username ALL=(ALL) NOPASSWD: ALL" > "$SUDO"
chmod 440 "$SUDO"
visudo -c
echo "Custom sudoers file created successfully."
sleep 1

#enabling multilib
sed -i 's/^#\[multilib\]/[multilib]/' /etc/pacman.conf
sed -i 's/^#Include = /etc/pacman.d/mirrorlist/Include = /etc/pacman.d/mirrorlist/' /etc/pacman.conf
sudo pacman -Sy
echo "Multilib repository enabled and package database updated."

#installing the AUR helper
if [ ! -f /usr/bin/yay ]; then
sudo pacman -S --noconfirm  --needed git go base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm
else echo "yay is already installed"
fi

#installing the desktop and apps
sudo pacman -Sy --noconfirm gnome gdm neofetch fastfetch gedit go samba sane cups flatpak kitty bluez bluez-utils timeshift btop vlc vulkan-radeon lib32-vulkan-radeon gnome-tweaks fuse wget
yay -S --needed --noconfirm arch-gaming-meta thorium-browser-bin vesktop ttf-ms-fonts auto-cpufreq protonup-qt
flatpak install -y flathub com.mattjakeman.ExtensionManager
flatpak install -y flathub it.mijorus.gearlever
flatpak install -y flathub io.github.peazip.PeaZip
flatpak install -y flathub com.dec05eba.gpu_screen_recorder
sudo systemctl enable gdm
echo "operation is finished. rebooting.."