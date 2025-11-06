#!/usr/bin/env bash
# ===============================================================
# 🧠 Omarchy Setup Script v3.0 — Intel Edition
# ---------------------------------------------------------------
# Autor: Marco G.
# Descripción:
#   Prepara un entorno completo de trabajo con Zsh, Oh My Zsh,
#   Oh My Posh, Homebrew, herramientas de desarrollo, codecs Intel,
#   drivers Epson, Logitech, VLC y utilidades varias.
#   Este script NO instala DaVinci Resolve, solo deja el sistema listo.
# ===============================================================

# ---------------------------------------------------------------
# 🧩 Función de seguridad: abortar si algo falla
# ---------------------------------------------------------------
set -e
trap 'echo "❌ Error en la línea $LINENO. Abortando instalación."; exit 1' ERR

# ---------------------------------------------------------------
# 🎨 Banner inicial estilo Catppuccin
# ---------------------------------------------------------------
cat << "EOF"
╔═════════════════════════════════════════════════════╗
║         🧠 Omarchy System Setup  v3.0               ║
║            Intel Iris Xe • Arch Linux               ║
╚═════════════════════════════════════════════════════╝
EOF
sleep 1

# ---------------------------------------------------------------
# 🧰 Actualización de sistema y herramientas base
# ---------------------------------------------------------------
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

# ---------------------------------------------------------------
# 🖥️ Instalación de controladores Intel Iris Xe
# ---------------------------------------------------------------
echo "🎞️ Instalando controladores y codecs para Intel Iris Xe..."
sudo pacman -S --needed --noconfirm \
  mesa libva-intel-driver intel-media-driver \
  vulkan-intel vulkan-icd-loader \
  libvdpau-va-gl libva-utils \
  gstreamer gst-libav gst-plugins-good gst-plugins-bad gst-plugins-ugly \
  ffmpeg opencl-clang intel-compute-runtime clinfo

# ---------------------------------------------------------------
# 🎵 Instalación de VLC + codecs + configuración predeterminada
# ---------------------------------------------------------------
echo "🎶 Instalando VLC y codecs multimedia..."
sudo pacman -S --needed --noconfirm vlc

# Establecer VLC como reproductor predeterminado de audio y video
echo "⚙️ Configurando VLC como reproductor predeterminado..."
xdg-mime default vlc.desktop audio/mpeg
xdg-mime default vlc.desktop audio/x-wav
xdg-mime default vlc.desktop audio/flac
xdg-mime default vlc.desktop video/mp4
xdg-mime default vlc.desktop video/x-matroska
xdg-mime default vlc.desktop video/x-msvideo
xdg-mime default vlc.desktop video/x-ms-wmv

# ---------------------------------------------------------------
# 🧾 Impresoras Epson (L4150 + Epson Scan2)
# ---------------------------------------------------------------
echo "🖨️ Instalando drivers Epson..."
sudo pacman -S --needed --noconfirm cups sane simple-scan
sudo systemctl enable --now cups.service
yay -S --needed --noconfirm epson-inkjet-printer-escpr2 epson-scanner-2

# ---------------------------------------------------------------
# 🖱️ Logitech: ltunify y logiops
# ---------------------------------------------------------------
echo "🖱️ Instalando soporte Logitech..."
sudo pacman -S --needed --noconfirm ltunify logiops

# ---------------------------------------------------------------
# 💻 Aplicaciones gráficas esenciales
# ---------------------------------------------------------------
echo "🪟 Instalando aplicaciones gráficas..."
sudo pacman -S --needed --noconfirm \
  filezilla gedit code cursor telegram-desktop

# ---------------------------------------------------------------
# 🧴 Instalación de Zsh + Oh My Zsh + plugins + Oh My Posh
# ---------------------------------------------------------------
echo "💄 Instalando Zsh y entorno de shell..."
sudo pacman -S --needed --noconfirm zsh

# Cambiar shell por defecto a Zsh
if [ "$SHELL" != "/bin/zsh" ]; then
    chsh -s /bin/zsh
fi

# Instalar Oh My Zsh si no existe
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "🌈 Instalando Oh My Zsh..."
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Instalar plugins
echo "🔌 Instalando plugins de Zsh..."
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions 2>/dev/null || true
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting 2>/dev/null || true
git clone https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/colorize $ZSH_CUSTOM/plugins/colorize 2>/dev/null || true

# Instalar Oh My Posh
echo "✨ Instalando Oh My Posh..."
curl -s https://ohmyposh.dev/install.sh | bash -s
oh-my-posh font install meslo

# ---------------------------------------------------------------
# 🍺 Instalación de Homebrew
# ---------------------------------------------------------------
echo "🍺 Instalando Homebrew..."
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# ---------------------------------------------------------------
# 🧩 Configuración de .bashrc (lanza Zsh + Homebrew env)
# ---------------------------------------------------------------
echo "⚙️ Ajustando ~/.bashrc..."
cat << 'EOBASH' > ~/.bashrc
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Omarchy default rc
source ~/.local/share/omarchy/default/bash/rc

# Lanzar Zsh automáticamente si no estamos ya en Zsh
if [ -t 1 ] && [ -z "$ZSH_VERSION" ]; then
    exec zsh
fi

# Inicializar Homebrew
eval "$($(brew --prefix)/bin/brew shellenv)"
EOBASH

# ---------------------------------------------------------------
# 🔐 Activar servicios básicos
# ---------------------------------------------------------------
echo "🔑 Habilitando servicios..."
sudo systemctl enable --now docker.service
sudo systemctl enable --now ntpd.service
sudo systemctl enable --now gnome-keyring-daemon.service || true

# ---------------------------------------------------------------
# ✅ Mensaje final
# ---------------------------------------------------------------
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║  ✅ Sistema preparado con éxito — Omarchy Setup v3.0       ║
║  Reinicia tu sesión o ejecuta 'exec zsh' para aplicar todo ║
║  Luego copia tu archivo .zshrc de Omarchy v2.1.            ║
╚═══════════════════════════════════════════════════════════╝
EOF
