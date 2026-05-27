#!/bin/bash

set -e

echo "=== CONFIGURANDO SISTEMA BASE ==="

ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc

echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

echo "LANG=pt_BR.UTF-8" > /etc/locale.conf

echo "archvm" > /etc/hostname

cat <<EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   archvm.localdomain archvm
EOF

echo "Instalando bootloader (systemd-boot)..."

bootctl install

mkdir -p /boot/loader/entries

cat <<EOF > /boot/loader/loader.conf
default arch
timeout 3
editor no
EOF

UUID=$(blkid -s UUID -o value /dev/sda2)

cat <<EOF > /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=UUID=$UUID rw
EOF

echo "Instalando pacotes extras..."
pacman -S --noconfirm networkmanager sudo

systemctl enable NetworkManager

echo "Defina a senha do root:"
passwd

echo "=== FINALIZADO ==="
echo "Agora saia: exit"
echo "Depois: umount -R /mnt && reboot"
