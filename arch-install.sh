#!/bin/bash

set -e

DISK="/dev/sda"

echo "Limpando disco..."
wipefs -a $DISK

echo "Criando tabela GPT..."
parted -s $DISK mklabel gpt

echo "Criando EFI (512MB)..."
parted -s $DISK mkpart ESP fat32 1MiB 513MiB
parted -s $DISK set 1 esp on

echo "Criando ROOT (restante do disco)..."
parted -s $DISK mkpart primary ext4 513MiB 100%

echo "Formatando partições..."
mkfs.fat -F32 ${DISK}1
mkfs.ext4 ${DISK}2

echo "Montando sistema..."
mount ${DISK}2 /mnt
mkdir -p /mnt/boot
mount ${DISK}1 /mnt/boot

echo "Instalando base system..."
pacstrap /mnt base linux linux-firmware nano networkmanager git base-devel sudo

echo "Gerando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "Pronto. Agora entre no sistema:"
echo "arch-chroot /mnt"
