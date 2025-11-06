#!/usr/bin/env bash
# ===============================================================
# 🧠 Omarchy Setup Script — Intel Edition
# ---------------------------------------------------------------
# Autor: Marco G.
# Descripción:
#   Prepara un entorno completo de trabajo con Zsh, Oh My Zsh,
#   Oh My Posh, Homebrew, herramientas de desarrollo, codecs Intel,
#   drivers Epson, Logitech y utilidades varias.
#   Este script también configura VLC como reproductor por defecto
#   y descarga tus archivos personalizados de Omarchy.
# ===============================================================

set -e
trap 'echo "❌ Error en la línea $LINENO. Abortando instalación."; exit 1' ERR

cat << "EOF"
╔═════════════════════════════════════════════════════╗
║         🧠 Omarchy System Setup                     ║
║            Intel Iris Xe • Arch Linux               ║
╚═════════════════════════════════════════════════════╝
EOF
sleep 1

echo "🔧 Actualizando sistema base..."
sudo pacman -Syu --noconfirm

echo "📦 Instalando utilidades esenciales..."
sudo pacman -S --needed --noconfirm \
  base-devel git curl wget zip unzip p7zip unrar tar \
  fastfetch nano htop btop eza tree zoxide bat fzf ripgrep \
  python python-pip nodejs npm go \
  docker docker-compose \
  gnome-keyring openssh lsof ntp \
  flatpak

echo "🎞️ Instalando controladores y codecs para Intel Iris Xe..."
sudo pacman -S --needed --noconfirm \
  mesa libva-intel-driver intel-media-driver \
  vulkan-intel vulkan-icd-loader \
  libvdpau-va-gl libva-utils \
  gstreamer gst-libav gst-plugins-good gst-plugins-bad gst-plugins-ugly \
  ffmpeg intel-compute-runtime clinfo

if ! pacman -Q opencl-clang &>/dev/null; then
  echo "⚙️ Instalando opencl-clang desde AUR..."
  yay -S --noconfirm opencl-clang || echo "⚠️ No se pudo instalar opencl-clang (omitido)."
fi

echo "🎧 Instalando VLC y codecs multimedia..."
sudo pacman -S --needed --noconfirm vlc vlc-plugins-all

echo "🗂️ Configurando VLC como reproductor por defecto..."
xdg-mime default vlc.desktop audio/mpeg
xdg-mime default vlc.desktop audio/mp3
xdg-mime default vlc.desktop audio/x-wav
xdg-mime default vlc.desktop video/mp4
xdg-mime default vlc.desktop video/x-matroska
xdg-mime default vlc.desktop video/x-msvideo

echo "🖨️ Instalando drivers Epson..."
sudo pacman -S --needed --noconfirm cups sane simple-scan
sudo systemctl enable --now cups.service
yay -S --needed --noconfirm epson-inkjet-printer-escpr2 epson-scanner-2 || echo "⚠️ Epson scanner no disponible en AUR."

# ---------------------------------------------------------------
# ✅ Verificar e instalar yay si no existe
# ---------------------------------------------------------------
if ! command -v yay &>/dev/null; then
  echo "📦 Instalando yay (AUR helper)..."
  cd /tmp
  git clone https://aur.archlinux.org/yay-bin.git
  cd yay-bin
  makepkg -si --noconfirm
  cd ~
fi

# ---------------------------------------------------------------
# 🖱️ Logitech: ltunify y logiops desde AUR
# ---------------------------------------------------------------
echo "🖱️ Instalando soporte Logitech..."
yay -S --noconfirm --needed ltunify logiops || echo "⚠️ No se pudieron instalar algunos paquetes Logitech (omitidos)."

echo "💻 Instalando aplicaciones gráficas..."
sudo pacman -S --needed --noconfirm filezilla gedit code cursor telegram-desktop

echo "💄 Instalando Zsh y entorno de shell..."
sudo pacman -S --needed --noconfirm zsh
if [ "$SHELL" != "/bin/zsh" ]; then
    chsh -s /bin/zsh
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "🌈 Instalando Oh My Zsh..."
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "🔌 Instalando plugins de Zsh..."
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions 2>/dev/null || true
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting 2>/dev/null || true
git clone https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/colorize $ZSH_CUSTOM/plugins/colorize 2>/dev/null || true

echo "✨ Instalando Oh My Posh..."
curl -s https://ohmyposh.dev/install.sh | bash -s
oh-my-posh font install meslo

echo "🍺 Instalando Homebrew..."
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "⚙️ Ajustando ~/.bashrc..."
cat << 'EOBASH' > ~/.bashrc
[[ $- != *i* ]] && return
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
if [ -t 1 ] && [ -z "$ZSH_VERSION" ]; then
    exec zsh
fi
EOBASH

echo "📥 Descargando configuraciones de Omarchy..."
mkdir -p ~/Omarchy
curl -fsSL -o ~/.zshrc "https://raw.githubusercontent.com/marcogll/scripts_mg/refs/heads/main/omarchy_zsh_setup/.zshrc"
curl -fsSL -o ~/Omarchy/omarchy-setup.sh "https://raw.githubusercontent.com/marcogll/scripts_mg/refs/heads/main/omarchy_zsh_setup/omarchy-setup.sh"
curl -fsSL -o ~/Omarchy/davinci_resolve_intel.sh "https://raw.githubusercontent.com/marcogll/scripts_mg/refs/heads/main/omarchy_zsh_setup/davince_resolve_intel.sh"
chmod +x ~/Omarchy/*.sh

echo "🔑 Habilitando servicios..."
sudo systemctl enable --now docker.service
sudo systemctl enable --now ntpd.service
sudo systemctl enable --now gnome-keyring-daemon.service || true

cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║  ✅ Sistema preparado con éxito — Omarchy Setup            ║
║  Reinicia tu sesión o ejecuta 'exec zsh' para aplicar todo ║
║  Archivos descargados en ~/Omarchy                        ║
╚═══════════════════════════════════════════════════════════╝
EOF
