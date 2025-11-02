#!/usr/bin/env bash
# =============================================================================
#     Omarchy Setup Script v2.5 (Omarchy-MG Edition)
#     Autor: Marco G. / 2025
#     Descripción:
#       Script de automatización para configurar un entorno Zsh completo
#       con Oh My Zsh, Oh My Posh, Docker, TeamViewer, Inkscape, Audacity,
#       y utilidades esenciales. Compatible con Arch Linux.
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
# FUNCIÓN: Verificar conexión a Internet
# =============================================================================
check_internet() {
  step "Verificando conexión a Internet..."
  if ! ping -c 1 archlinux.org &>/dev/null; then
    error "Sin conexión a Internet. Abortando instalación."
    exit 1
  fi
  success "Conexión a Internet verificada."
}

# =============================================================================
# FUNCIÓN: Actualizar sistema y dependencias base
# =============================================================================
install_base_packages() {
  step "Actualizando sistema e instalando paquetes base"
  sudo pacman -Syu --noconfirm

  # Paquetes esenciales del sistema
  local pkgs=(
    git curl wget unzip tar base-devel
    zsh zsh-completions
    eza bat zoxide
    docker docker-compose
    teamviewer
    audacity inkscape
    oh-my-posh
  )

  # Instalar con yay o pacman dependiendo de la disponibilidad
  if command -v yay &>/dev/null; then
    yay -S --noconfirm "${pkgs[@]}"
  else
    sudo pacman -S --needed --noconfirm "${pkgs[@]}"
  fi

  success "Paquetes base instalados correctamente."
}

# =============================================================================
# FUNCIÓN: Configurar Docker
# =============================================================================
setup_docker() {
  step "Configurando Docker y permisos de usuario"
  sudo systemctl enable docker.service
  sudo systemctl start docker.service

  # Agregar usuario al grupo docker para evitar usar sudo
  sudo usermod -aG docker "$USER"
  success "Docker configurado. Recuerda cerrar y volver a iniciar sesión."
}

# =============================================================================
# FUNCIÓN: Instalar Oh My Zsh y plugins
# =============================================================================
install_ohmyzsh() {
  step "Instalando Oh My Zsh y sus plugins"

  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    # Instalar Oh My Zsh sin preguntar
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    log "Oh My Zsh ya está instalado, se omite."
  fi

  # Crear carpeta custom de plugins si no existe
  mkdir -p "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

  # Instalar plugins adicionales
  git clone https://github.com/zsh-users/zsh-autosuggestions.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" || true

  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" || true

  success "Oh My Zsh y plugins instalados correctamente."
}

# =============================================================================
# FUNCIÓN: Descargar y aplicar el .zshrc personalizado
# =============================================================================
install_zshrc() {
  step "Aplicando configuración personalizada de Zsh (.zshrc)"
  local ZSHRC_URL="https://raw.githubusercontent.com/marcogll/scripts_mg/main/omarchy_zsh_setup/.zshrc"
  local DEST="$HOME/.zshrc"

  # Backup del anterior
  if [ -f "$DEST" ]; then
    cp "$DEST" "${DEST}.backup.$(date +%Y%m%d_%H%M%S)"
    log "Backup del .zshrc existente creado."
  fi

  # Descargar el nuevo
  if curl -fsSL "$ZSHRC_URL" -o "$DEST"; then
    success "Nuevo .zshrc instalado desde GitHub."
  else
    error "Fallo al descargar .zshrc desde $ZSHRC_URL"
  fi

  # Cambiar shell por defecto a zsh
  chsh -s "$(which zsh)" "$USER" || true
}

# =============================================================================
# FUNCIÓN: Configurar TeamViewer (servicio)
# =============================================================================
setup_teamviewer() {
  step "Configurando TeamViewer"
  sudo systemctl enable teamviewerd.service
  sudo systemctl start teamviewerd.service
  success "TeamViewer habilitado y activo."
}

# =============================================================================
# FUNCIÓN: Instalación de fuentes y temas (opcional)
# =============================================================================
install_fonts() {
  step "Instalando fuentes para Oh My Posh y terminal"
  local FONTS_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONTS_DIR"

  # Ejemplo: instalar JetBrainsMono Nerd Font
  if [ ! -f "$FONTS_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]; then
    curl -fsSL -o "$FONTS_DIR/JetBrainsMonoNerdFont-Regular.ttf" \
      "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/Regular/complete/JetBrains%20Mono%20Nerd%20Font%20Complete.ttf"
    fc-cache -f
  fi

  success "Fuentes Nerd instaladas."
}

# =============================================================================
# FUNCIÓN: Limpieza y resumen final
# =============================================================================
finish_setup() {
  step "Finalizando configuración"

  echo -e "\n${GREEN}🎉 Instalación completada correctamente.${RESET}"
  echo -e "Reinicia tu sesión o ejecuta ${YELLOW}zsh${RESET} para activar la configuración."
  echo -e "\nVerifica:"
  echo " - Docker: 'docker ps'"
  echo " - Zsh funcionando con Oh My Posh"
  echo " - TeamViewer corriendo (teamviewer info)"
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
  install_zshrc
  setup_teamviewer
  install_fonts
  finish_setup
}

main "$@"
