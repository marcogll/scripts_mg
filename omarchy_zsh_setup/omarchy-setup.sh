#!/bin/bash

# ================================================================
# Omarchy Zsh Setup Script v2.4
# Author: Marco G
# Description: Automated Zsh environment setup for Arch/Omarchy Linux
# ================================================================

set -Eeo pipefail

LOG_FILE="omarchy-setup.log"
ERROR_LOG="omarchy-errors.log"
START_TIME=$(date +%s)
NEEDS_REBOOT=false

# Colors
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
NC="\e[0m"

# Logging
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}✗${NC} $1" | tee -a "$ERROR_LOG" >&2; }
success() { echo -e "${GREEN}✓${NC} $1"; log "SUCCESS: $1"; printf '\a'; }
step() { echo -e "\n${BLUE}→${NC} $1"; log "STEP: $1"; }

# Progress bar
progress_bar() {
  local duration=$1
  local interval=0.2
  local elapsed=0
  echo -n "["
  while (( $(echo "$elapsed < $duration" | bc -l) )); do
    echo -n "#"
    sleep $interval
    elapsed=$(echo "$elapsed + $interval" | bc)
  done
  echo "]"
}

# Internet check
check_internet() {
  if ! ping -c1 archlinux.org &>/dev/null; then
    error "Sin conexión a Internet. Abortando instalación."
    exit 1
  fi
}

# Package installation
yay_install() {
  local packages=($@)
  for pkg in "${packages[@]}"; do
    if ! pacman -Qi $pkg &>/dev/null; then
      yay -S --noconfirm --needed $pkg || error "Error instalando $pkg"
    else
      log "$pkg ya está instalado."
    fi
  done
}

# Install yay if missing
install_yay() {
  if ! command -v yay &>/dev/null; then
    step "Instalando yay desde AUR..."
    mkdir -p /tmp/yay
    cd /tmp/yay
    git clone https://aur.archlinux.org/yay.git .
    makepkg -si --noconfirm
    cd - >/dev/null
    rm -rf /tmp/yay
    success "yay instalado correctamente."
  else
    log "yay ya está instalado."
  fi
}

# Base system packages
install_base_packages() {
  step "Instalando paquetes base..."
  yay_install git curl wget zsh neovim unzip p7zip tree fzf ripgrep bat exa htop btop nano
  success "Paquetes base instalados."
}

# GNOME Keyring configuration (skipped if no graphical session)
configure_gnome_keyring() {
  if [ -n "$DISPLAY" ]; then
    step "Configurando GNOME Keyring..."
    yay_install gnome-keyring libsecret seahorse
    mkdir -p ~/.config/systemd/user
    systemctl --user enable gcr-ssh-agent.socket || true
    systemctl --user start gcr-ssh-agent.socket || true
    success "GNOME Keyring configurado."
  else
    log "Entorno sin interfaz gráfica, se omite GNOME Keyring."
  fi
}

# Install Oh My Zsh
install_oh_my_zsh() {
  step "Instalando Oh My Zsh..."
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    success "Oh My Zsh instalado."
  else
    log "Oh My Zsh ya está instalado."
  fi
}

# Install Zsh plugins
install_zsh_plugins() {
  step "Instalando plugins de Zsh..."
  mkdir -p ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins

  local plugins=(
    "zsh-users/zsh-autosuggestions"
    "zsh-users/zsh-syntax-highlighting"
    "zsh-users/zsh-completions"
  )

  for repo in "${plugins[@]}"; do
    local name=$(basename "$repo")
    local path="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/$name"
    if [ ! -d "$path" ]; then
      git clone https://github.com/$repo "$path"
      log "Plugin $name instalado."
    else
      log "Plugin $name ya existe."
    fi
  done
  success "Plugins de Zsh instalados."
}

# Install Oh My Posh
install_oh_my_posh() {
  step "Instalando Oh My Posh..."
  yay_install oh-my-posh
  mkdir -p ~/.poshthemes
  curl -fsSL https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/jandedobbeleer.omp.json -o ~/.poshthemes/omarchy.omp.json
  success "Oh My Posh instalado."
}

# Create .zshrc
create_zshrc() {
  step "Creando configuración de Zsh..."
  cat > ~/.zshrc <<'EOF'
# ================================================================
# Omarchy Zsh Configuration
# ================================================================

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)
source $ZSH/oh-my-zsh.sh

# Aliases y extras
alias ll='exa -lh --icons'
alias la='exa -lha --icons'
alias gs='git status'
alias v='nvim'

# Oh My Posh
if command -v oh-my-posh &>/dev/null; then
  eval "$(oh-my-posh init zsh --config ~/.poshthemes/omarchy.omp.json)"
fi

# PATH
export PATH="$HOME/.local/bin:$PATH"
EOF
  success ".zshrc creado."
}

# Configure SSH
configure_ssh() {
  step "Configurando SSH..."
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f ~/.ssh/id_ed25519 -N ""
    success "Clave SSH generada."
  else
    log "Clave SSH existente detectada."
  fi
  eval "$(ssh-agent -s)" >/dev/null
  ssh-add ~/.ssh/id_ed25519 || true
  for key in ~/.ssh/*.pub; do
    log "Clave pública: $(cat $key)"
  done
  success "SSH configurado."
}

# Final summary
finish_installation() {
  END_TIME=$(date +%s)
  DURATION=$((END_TIME - START_TIME))
  echo -e "\n${GREEN}Instalación completada.${NC}"
  echo -e "Duración: ${DURATION}s"
  echo -e "Logs: ${LOG_FILE}"
  echo -e "Errores: ${ERROR_LOG}"
  $NEEDS_REBOOT && echo -e "${YELLOW}Se recomienda reiniciar el sistema.${NC}"
  echo -e "${BLUE}Para activar zsh como shell predeterminada, ejecuta:${NC} chsh -s $(which zsh)"
}

# ================================================================
# MAIN EXECUTION FLOW
# ================================================================

step "Verificando entorno y conexión..."
check_internet
install_yay
install_base_packages
configure_gnome_keyring
install_oh_my_zsh
install_zsh_plugins
install_oh_my_posh
create_zshrc
configure_ssh
finish_installation

success "Setup completo. Reinicia o ejecuta 'zsh' para aplicar cambios."
