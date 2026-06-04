#!/bin/bash
set -e

echo "=== EXPANSE OS CHROOT FINAL ==="
USER="expanse"
BASE="/home/$USER/workspace"

echo "=== BASE SYSTEM ==="
pacman -S --noconfirm \
  efibootmgr \
  hyprland xdg-desktop-portal-hyprland kitty \
  pipewire pipewire-pulse wireplumber \
  wl-clipboard xdg-utils hyprpaper noto-fonts-emoji
  
systemctl enable NetworkManager

echo "=== SYSTEMD-BOOT INSTALL ==="
bootctl install
mkdir -p /boot/loader/entries

cat <<EOF > /boot/loader/loader.conf
default expanse
timeout 3
editor no
EOF

ROOT_UUID=$(blkid -s UUID -o value $(findmnt -n -o SOURCE /))

cat <<EOF > /boot/loader/entries/expanse.conf
title   Expanse OS
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=$ROOT_UUID rw
EOF

# Sincroniza o kernel instalado com o gerenciador de boot
mkinitcpio -p linux

echo "=== USER SETUP ==="
if ! id "$USER" &>/dev/null; then
    useradd -m -G wheel $USER
fi
echo "$USER:expanse" | chpasswd
sed -i '/%wheel ALL=(ALL:ALL) ALL/d' /etc/sudoers
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

echo "=== AUTO LOGIN ==="
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat <<EOF > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USER --noclear %I \$TERM
EOF

echo "=== AUTO START HYPRLAND ==="
cat <<EOF > /home/$USER/.bash_profile
if [[ -z \$WAYLAND_DISPLAY ]] && [[ \$(tty) == /dev/tty1 ]]; then
    exec Hyprland
fi
EOF
chown $USER:$USER /home/$USER/.bash_profile

mkdir -p /home/$USER/.config/fontconfig/conf.d

cat <<EOF > /home/$USER/.config/fontconfig/conf.d/75-noto-color-emoji.conf
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>

  <match target="pattern">
    <test qual="any" name="family">
      <string>sans-serif</string>
    </test>
    <edit name="family" mode="append">
      <string>Noto Color Emoji</string>
    </edit>
  </match>

</fontconfig>
EOF

fc-cache -fv

chown -R $USER:$USER /home/$USER/.config
echo "Configuração do chroot concluída!"



