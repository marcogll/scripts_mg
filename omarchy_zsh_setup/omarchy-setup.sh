#!/usr/bin/env bash
# =============================================================================
#     Omarchy Setup Script v2.6 (Omarchy-MG Edition) - Arch Update
#     Autor: Marco G. / 2025
#     Descripción:
#       Script de automatización para configurar un entorno Zsh completo
#       con Oh My Zsh, Oh My Posh (tema Catppuccin Frappe), Docker, TeamViewer,
#       Inkscape, Audacity, speedtest-cli y utilidades esenciales.
# =============================================================================

set -euo pipefail

# =============================================================================
# COLORES Y UTILIDADES DE LOGGING
# =============================================================================
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

step()    { echo -e "\n${YELLOW}→ $1${RESET}"; sleep 0.3; }
success() { echo -e "${GREEN}✓ $1${RESET}"; }
error()   { echo -e "${RED}✗ $1${RESET}" >&2; }
log()     { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

# =============================================================================
# FUNCIONES PRINCIPALES
# =============================================================================
check_internet() {
  step "Verificando conexión a Internet..."
  if ! ping -c 1 archlinux.org &>/dev/null; then
    error "Sin conexión a Internet. Abortando instalación."
    exit 1
  fi
  success "Conexión a Internet verificada."
}

install_base_packages() {
  step "Actualizando sistema e instalando paquetes base"
  sudo pacman -Syu --noconfirm

  local pkgs=(git curl wget unzip tar base-devel zsh zsh-completions eza bat zoxide docker docker-compose teamviewer audacity inkscape oh-my-posh python-pip)

  if command -v yay &>/dev/null; then
    yay -S --noconfirm "${pkgs[@]}"
  else
    sudo pacman -S --needed --noconfirm "${pkgs[@]}"
  fi

  # Instalar speedtest-cli si no está presente
  if ! command -v speedtest &>/dev/null; then
    sudo pip install speedtest-cli
  fi

  success "Paquetes base y speedtest-cli instalados correctamente."
}

setup_docker() {
  step "Configurando Docker y permisos de usuario"
  sudo systemctl enable docker.service
  sudo systemctl start docker.service
  sudo usermod -aG docker "$USER"
  success "Docker configurado. Recuerda cerrar y volver a iniciar sesión."
}

install_ohmyzsh() {
  step "Instalando Oh My Zsh y sus plugins"
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    log "Oh My Zsh ya está instalado, se omite."
  fi

  mkdir -p "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
  git clone https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" || true
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" || true
  success "Oh My Zsh y plugins instalados correctamente."
}

install_zshrc_and_posh_theme() {
  step "Aplicando configuración personalizada de Zsh (.zshrc) y tema Catppuccin Frappe"
  local ZSHRC_URL="https://raw.githubusercontent.com/marcogll/scripts_mg/main/omarchy_zsh_setup/.zshrc"
  local DEST="$HOME/.zshrc"

  if [ -f "$DEST" ]; then
    cp "$DEST" "${DEST}.backup.$(date +%Y%m%d_%H%M%S)"
    log "Backup del .zshrc existente creado."
  fi

  if curl -fsSL "$ZSHRC_URL" -o "$DEST"; then
    success "Nuevo .zshrc instalado desde GitHub."
  else
    error "Fallo al descargar .zshrc desde $ZSHRC_URL"
  fi

  mkdir -p ~/.poshthemes
  wget https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/catppuccin_frappe.omp.json -O ~/.poshthemes/catppuccin.omp.json
  success "Tema Catppuccin Frappe descargado en ~/.poshthemes/"

  chsh -s "$(which zsh)" "$USER" || true
}

setup_teamviewer() {
  step "Configurando TeamViewer"
  sudo systemctl enable teamviewerd.service
  sudo systemctl start teamviewerd.service
  success "TeamViewer habilitado y activo."
}

install_fonts() {
  step "Instalando fuentes para Oh My Posh y terminal"
  local FONTS_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONTS_DIR"
  if [ ! -f "$FONTS_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]; then
    curl -fsSL -o "$FONTS_DIR/JetBrainsMonoNerdFont-Regular.ttf" \
      "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/Regular/complete/JetBrains%20Mono%20Nerd%20Font%20Complete.ttf"
    fc-cache -f
  fi
  success "Fuentes Nerd instaladas."
}

finish_setup() {
  step "Finalizando configuración"
  echo -e "\n${GREEN}🎉 Instalación completada correctamente.${RESET}"
  echo -e "Reinicia tu sesión o ejecuta ${YELLOW}zsh${RESET} para activar la configuración."
  echo -e "\nVerifica:"
  echo " - Docker: 'docker ps'"
  echo " - Zsh funcionando con Oh My Posh"
  echo " - TeamViewer corriendo (teamviewer info)"
  echo " - speedtest-cli: 'speedtest'"
  echo -e "\n🚀 ¡Listo para usar Omarchy en todo su esplendor!"
}

# =============================================================================
# MAIN
# =============================================================================
main() {
  check_internet
  install_base_packages
  setup_docker
  install_ohmyzsh
  install_zshrc_and_posh_theme
  setup_teamviewer
  install_fonts
  finish_setup
}

main "$@"
