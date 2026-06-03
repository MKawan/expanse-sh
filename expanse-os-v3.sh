#!/bin/bash
set -e

USER="expanse"
BASE="/home/$USER/workspace"

echo "=== INSTALL DEV STACK ==="
sudo pacman -S --noconfirm \
  nodejs npm \
  webkit2gtk-4.1 gtk3 libsoup3 \
  cmake ninja gcc clang \
  rustup

sudo npm install -g pnpm
rustup default stable

# Instalação do VSCodium via repositório não-root (Simulação segura para script)
if ! command -v vscodium &> /dev/null; then
  echo "Para desenvolvimento, instale o vscodium posteriormente via AUR como usuário comum."
fi

echo "=== CRIANDO WORKSPACE DO ECOSSISTEMA ==="
sudo -u $USER bash <<EOF
set -e
mkdir -p "$BASE"
cd "$BASE"
rm -rf expanse-shell || true

# Cria diretamente a estrutura do tauri integrada ao Vite+React+TS de forma limpa
npx create-tauri-app@latest expanse-shell \
  --manager npm \
  --template react-ts \
  --y

cd expanse-shell
npm install

echo "=== CUSTOMIZANDO TAURI PARA MODO KIOSK / FULLSCREEN (TAURI V2) ==="
# Injeta as configurações corrigidas e validadas para a especificação do Tauri v2
cat <<EOT > src-tauri/tauri.conf.json
{
  "productName": "expanse-shell",
  "version": "0.1.0",
  "identifier": "com.expanse.shell",
"build": {
  "beforeDevCommand": "npm run dev",
  "devUrl": "http://localhost:1420"
},
  "app": {
    "windows": [
      {
        "title": "expanse-shell",
        "width": 1920,
        "height": 1080,
        "resizable": false,
        "fullscreen": true,
        "decorations": false
      }
    ]
  },
  "bundle": {
    "active": true,
    "targets": ["updater"]
  }
}
EOT

echo "=== ANTECIPANDO DOWNLOAD E COMPILAÇÃO DO RUST ==="
# Baixa e compila as dependências do Rust agora. Evita que o primeiro boot trave!
npm run tauri build -- --debug || true

echo "=== START DEV SCRIPT ==="
cat <<EOT > start-dev.sh
#!/bin/bash

export PATH=$PATH:/home/expanse/.cargo/bin:/usr/bin

export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=Hyprland

export GDK_BACKEND=wayland
export WEBKIT_DISABLE_DMABUF_RENDERER=1

export LIBGL_ALWAYS_SOFTWARE=1

cd /home/expanse/workspace/expanse-shell

npm run tauri dev
EOT

chmod +x start-dev.sh
EOF

echo "=== FINALIZADO ==="
echo "Workspace pronto e atualizado para v2: $BASE/expanse-shell"
