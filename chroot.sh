#!/bin/bash
set -e

echo "=== EXPANSE OS CHROOT FINAL ==="

USER="expanse"

# =========================
# 1. PACOTES BASE
# =========================

echo "=== BASE SYSTEM ==="

pacman -S --noconfirm \
linux linux-firmware \
networkmanager \
sudo \
vim nano \
efibootmgr \
base-devel \
git curl wget

systemctl enable NetworkManager

# =========================
# 2. BOOTLOADER (SYSTEMD-BOOT)
# =========================

echo "=== SYSTEMD-BOOT INSTALL ==="

bootctl install

mkdir -p /boot/loader/entries

cat <<EOF > /boot/loader/loader.conf
default expanse
timeout 3
editor no
EOF

# pega UUID automaticamente (root = /)
ROOT_UUID=$(blkid -s UUID -o value $(findmnt -n -o SOURCE /))

cat <<EOF > /boot/loader/entries/expanse.conf
title   Expanse OS
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=$ROOT_UUID rw
EOF

# =========================
# 3. USUÁRIO
# =========================

echo "=== USER SETUP ==="

useradd -m -G wheel $USER
echo "$USER:expanse" | chpasswd

echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# =========================
# 4. AUTO LOGIN TTY1
# =========================

echo "=== AUTO LOGIN ==="

mkdir -p /etc/systemd/system/getty@tty1.service.d

cat <<EOF > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USER --noclear %I \$TERM
EOF

# =========================
# 5. RUNTIME GRAFICO
# =========================

echo "=== WAYLAND + HYPRLAND ==="

pacman -S --noconfirm \
hyprland \
xdg-desktop-portal-hyprland \
kitty \
pipewire pipewire-pulse wireplumber \
wl-clipboard \
xdg-utils

# =========================
# 6. AUTO START HYPRLAND
# =========================

echo "=== AUTO START HYPRLAND ==="

cat <<EOF >> /home/$USER/.bash_profile

if [[ -z \$WAYLAND_DISPLAY ]] && [[ \$(tty) == /dev/tty1 ]]; then
    exec Hyprland
fi

EOF

chown $USER:$USER /home/$USER/.bash_profile

# =========================
# 7. EXPANSE SHELL (TAURI + VITE START)
# =========================

echo "=== SHELL START CONFIG ==="

mkdir -p /home/$USER/workspace/expanse-shell

cat <<EOF > /home/$USER/workspace/expanse-shell/start.sh
#!/bin/bash

cd /home/$USER/workspace/expanse-shell

# modo dev
npm run dev &
sleep 3
npm run tauri dev
EOF

chmod +x /home/$USER/workspace/expanse-shell/start.sh
chown -R $USER:$USER /home/$USER/workspace

# =========================
# 8. HYPRLAND AUTO START SHELL
# =========================

mkdir -p /home/$USER/.config/hypr

cat <<EOF > /home/$USER/.config/hypr/hyprland.conf

# ExpansE OS Shell auto start
exec-once = /home/$USER/workspace/expanse-shell/start.sh

EOF

chown -R $USER:$USER /home/$USER/.config

# =========================
# 9. FINAL MESSAGE
# =========================

echo "=== INSTALL COMPLETO ==="
echo "Agora saia do chroot e reinicie:"
echo "umount -R /mnt"
echo "reboot"
