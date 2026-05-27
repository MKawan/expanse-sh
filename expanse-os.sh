#!/bin/bash
set -e

USER="expanse"
BASE="/home/$USER/workspace"

echo "=== INSTALL DEV STACK ==="

sudo pacman -S --noconfirm \
nodejs npm rustup \
git curl wget \
base-devel \
webkit2gtk gtk3 libsoup \
cmake ninja gcc clang \
codium

sudo npm install -g pnpm
rustup default stable

echo "=== CRIANDO WORKSPACE ==="

sudo -u $USER bash <<EOF

mkdir -p $BASE
cd $BASE

rm -rf expanse-shell || true

echo "=== VITE + TAURI PROJECT ==="

npm create vite@latest expanse-shell -- --template react-ts
cd expanse-shell

npm install

echo "=== TAURI INIT ==="
cargo install create-tauri-app || true
npx tauri init --ci

echo "=== CONFIGURAÇÃO AUTOMÁTICA TAURI ==="

cat <<EOT > src-tauri/tauri.conf.json
{
  "build": {
    "devPath": "http://127.0.0.1:5173",
    "distDir": "../dist"
  }
}
EOT

echo "=== START SCRIPT ==="

cat <<EOT > start-dev.sh
#!/bin/bash

cd $BASE/expanse-shell

npm run dev &
sleep 3
npm run tauri dev
EOT

chmod +x start-dev.sh

EOF

echo "=== CONFIG VSCODIUM WORKSPACE ==="

sudo -u $USER bash <<EOF
codium $BASE
EOF

echo "=== FINALIZADO ==="
echo "Workspace pronto: $BASE/expanse-shell"
