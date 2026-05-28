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

# Descobre os nomes reais para evitar bugs de nomenclatura do kernel
PART_EFI=$(lsblk -nxo PATH "$DISK" | sed -n '2p')
PART_ROOT=$(lsblk -nxo PATH "$DISK" | sed -n '3p')

echo "Formatando partições..."
mkfs.fat -F32 "$PART_EFI"
mkfs.ext4 -F "$PART_ROOT"

echo "Montando sistema..."
mount "$PART_ROOT" /mnt
mkdir -p /mnt/boot
mount "$PART_EFI" /mnt/boot

echo "Instalando base system..."
# Adicionado pacotes essenciais para compilação futura
pacstrap -K /mnt base linux linux-firmware nano networkmanager git base-devel sudo

echo "Gerando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "Pronto. Agora entre no sistema:"
echo "arch-chroot /mnt"
