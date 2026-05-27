#!/bin/bash
set -e

USER="expanse"
BASE="/home/$USER/workspace"

echo "=== INSTALL DEV STACK ==="

# base system tools
sudo pacman -S --noconfirm \
nodejs npm \
git curl wget \
base-devel \
webkit2gtk-4.1 gtk3 libsoup \
cmake ninja gcc clang \
rustup

# pnpm
sudo npm install -g pnpm

# rust
rustup default stable

# yay (AUR helper para VSCodium)
if ! command -v yay &> /dev/null; then
  echo "=== INSTALL YAY ==="
  sudo pacman -S --noconfirm git base-devel
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  cd /tmp/yay
  makepkg -si --noconfirm
fi

# VSCodium (CORRETO)
yay -S --noconfirm vscodium-bin

echo "=== CRIANDO WORKSPACE ==="

sudo -u $USER bash <<EOF

mkdir -p $BASE
cd $BASE

rm -rf expanse-shell || true

echo "=== VITE PROJECT ==="
npm create vite@latest expanse-shell -- --template react-ts

cd expanse-shell
npm install

echo "=== TAURI INIT (CORRETO) ==="
npx create-tauri-app@latest . --ci --template react-ts

echo "=== CONFIG TAURI DEV ==="

cat <<EOT > src-tauri/tauri.conf.json
{
  "build": {
    "devPath": "http://127.0.0.1:5173",
    "distDir": "../dist"
  }
}
EOT

echo "=== START DEV SCRIPT ==="

cat <<EOT > start-dev.sh
#!/bin/bash

cd $BASE/expanse-shell

npm run dev &
sleep 3
npm run tauri dev
EOT

chmod +x start-dev.sh

EOF

echo "=== ABRINDO VSCODIUM NO PROJETO ==="

sudo -u $USER bash <<EOF
vscodium $BASE/expanse-shell
EOF

echo "=== FINALIZADO ==="
echo "Workspace pronto: $BASE/expanse-shell"
