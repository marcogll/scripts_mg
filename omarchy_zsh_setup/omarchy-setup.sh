#!/bin/bash

# =============================================================================
#                   OMARCHY ZSH SETUP SCRIPT v2.1
# =============================================================================
# GitHub: https://github.com/marcogll/scripts_mg
# Instalación: bash <(curl -fsSL https://raw.githubusercontent.com/marcogll/scripts_mg/main/omarchy_zsh_setup/omarchy-setup.sh)
#
# Uso:
#   bash omarchy-setup.sh          # Instalación completa
#   bash omarchy-setup.sh --ssh    # Solo configurar SSH
#   bash omarchy-setup.sh --help   # Mostrar ayuda
# =============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

TOTAL_STEPS=20
CURRENT_STEP=0
ZEROTIER_NETWORK=""
KEYRING_PASSWORD=""
NEEDS_REBOOT=false

# Logging
LOG_FILE="$HOME/omarchy-setup.log"
ERROR_LOG="$HOME/omarchy-errors.log"

# =============================================================================
# LOGGING
# =============================================================================

setup_logging() {
    # Crear archivos de log
    : > "$LOG_FILE"
    : > "$ERROR_LOG"
    
    # Redirigir stdout y stderr
    exec > >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$ERROR_LOG" >&2)
    
    log "==================================================================="
    log "OMARCHY SETUP v2.1 - $(date '+%Y-%m-%d %H:%M:%S')"
    log "==================================================================="
}

log() {
    echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%H:%M:%S')] ERROR: $*" | tee -a "$ERROR_LOG" >&2
}

# =============================================================================
# FUNCIONES AUXILIARES
# =============================================================================

print_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}${BOLD}        OMARCHY ZSH SETUP v2.1 - Setup Completo${NC}             ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Logs:${NC} $LOG_FILE"
    echo -e "${CYAN}Errores:${NC} $ERROR_LOG"
    echo ""
}

progress_bar() {
    local step=$1
    local total=$2
    local text=$3
    local percent=$((step * 100 / total))
    local completed=$((step * 50 / total))
    local remaining=$((50 - completed))
    
    printf "\r${BLUE}[${NC}"
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "${BLUE}]${NC} ${percent}%% - ${text}"
}

step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo ""
    log "STEP ${CURRENT_STEP}/${TOTAL_STEPS}: $1"
    echo -e "${GREEN}[${CURRENT_STEP}/${TOTAL_STEPS}]${NC} ${BOLD}$1${NC}"
    progress_bar $CURRENT_STEP $TOTAL_STEPS "$1"
    echo ""
}

success() { 
    echo -e "${GREEN}✓${NC} $1"
    log "SUCCESS: $1"
}

warning() { 
    echo -e "${YELLOW}⚠${NC} $1"
    log "WARNING: $1"
}

error() { 
    echo -e "${RED}✗${NC} $1"
    log_error "$1"
}

info() { 
    echo -e "${CYAN}ℹ${NC} $1"
    log "INFO: $1"
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    
    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    while true; do
        read -p "$(echo -e ${YELLOW}$prompt${NC})" response
        response=${response:-$default}
        case $response in
            [Yy]* ) log "USER: $prompt -> YES"; return 0;;
            [Nn]* ) log "USER: $prompt -> NO"; return 1;;
            * ) echo "Por favor responde sí (y) o no (n).";;
        esac
    done
}

check_installed() {
    local pkg=$1
    pacman -Q "$pkg" &> /dev/null
}

# =============================================================================
# VERIFICACIONES
# =============================================================================

check_requirements() {
    if [ "$EUID" -eq 0 ]; then 
        error "No ejecutes este script como root"
        exit 1
    fi
    
    if ! command -v pacman &> /dev/null; then
        error "Este script es solo para Arch Linux / Omarchy"
        exit 1
    fi
    
    success "Sistema compatible detectado"
}

# =============================================================================
# INSTALACIÓN DE PAQUETES
# =============================================================================

install_packages() {
    step "Instalando paquetes base"
    
    local packages=(
        "zsh" "git" "curl" "wget"
        "python" "python-pip" "python-virtualenv"
        "nodejs" "npm"
        "go"
        "zoxide"
        "docker" "docker-compose"
        "yt-dlp" "ffmpeg"
        "playerctl" "brightnessctl" "pamixer"
        "lsof" "net-tools"
        "gnome-keyring" "libsecret" "seahorse"
        "cups" "cups-pdf" "system-config-printer"
        "gutenprint" "foomatic-db-gutenprint-ppds"
        "tumbler" "ffmpegthumbnailer" "poppler-glib"
        "gdk-pixbuf2" "gst-plugins-good" "gst-plugins-bad"
        "gst-plugins-ugly" "gst-libav" "libheif" "webp-pixbuf-loader"
        "fastfetch" "htop" "btop" "tree" "unzip" "p7zip" "unrar"
    )
    
    info "Actualizando base de datos de paquetes..."
    sudo pacman -Sy --noconfirm
    
    local to_install=()
    local total=${#packages[@]}
    local current=0
    
    for pkg in "${packages[@]}"; do
        current=$((current + 1))
        if ! check_installed "$pkg"; then
            to_install+=("$pkg")
        fi
        printf "\r  Verificando paquetes... [%d/%d]" $current $total
    done
    echo ""
    
    if [ ${#to_install[@]} -eq 0 ]; then
        success "Todos los paquetes ya están instalados"
        return
    fi
    
    info "Instalando ${#to_install[@]} paquetes nuevos..."
    log "Paquetes a instalar: ${to_install[*]}"
    
    if sudo pacman -S --noconfirm --needed "${to_install[@]}"; then
        success "Paquetes instalados: ${#to_install[@]}"
    else
        error "Fallo al instalar algunos paquetes"
        log_error "Paquetes que fallaron: revisar log de pacman"
    fi
}

install_yay() {
    step "Instalando yay (AUR helper)"
    
    if command -v yay &> /dev/null; then
        success "yay ya está instalado"
        return
    fi
    
    info "Clonando yay desde AUR..."
    cd /tmp
    rm -rf yay
    git clone https://aur.archlinux.org/yay.git --quiet
    cd yay
    
    info "Compilando yay..."
    if makepkg -si --noconfirm --nocheck; then
        cd ~
        success "yay instalado"
    else
        cd ~
        error "Fallo al instalar yay"
        exit 1
    fi
}

install_oh_my_posh() {
    step "Instalando Oh My Posh"
    
    if command -v oh-my-posh &> /dev/null; then
        success "Oh My Posh ya está instalado"
        return
    fi
    
    info "Intentando instalar oh-my-posh-bin desde AUR..."
    log "Método 1: Instalación desde AUR"
    
    if yay -S --noconfirm oh-my-posh-bin 2>&1 | tee -a "$LOG_FILE"; then
        success "Oh My Posh instalado desde AUR"
        return
    fi
    
    warning "Fallo instalación desde AUR, intentando con script oficial..."
    log "Método 2: Script de instalación oficial"
    
    info "Descargando e instalando Oh My Posh..."
    if curl -s https://ohmyposh.dev/install.sh | bash -s 2>&1 | tee -a "$LOG_FILE"; then
        # Agregar al PATH si se instaló en ~/.local/bin
        export PATH="$HOME/.local/bin:$PATH"
        
        if command -v oh-my-posh &> /dev/null; then
            success "Oh My Posh instalado con script oficial"
            
            # Asegurar que esté en el PATH permanentemente
            if ! grep -q ".local/bin" "$HOME/.zshrc" 2>/dev/null; then
                info "Agregando ~/.local/bin al PATH..."
            fi
        else
            error "Fallo al instalar Oh My Posh"
            warning "Continuando sin Oh My Posh (puedes instalarlo después)"
        fi
    else
        error "Fallo al instalar Oh My Posh con script oficial"
        warning "Continuando sin Oh My Posh"
    fi
}


install_localsend() {
    step "Instalando LocalSend"
    
    if command -v localsend_app &> /dev/null; then
        success "LocalSend ya está instalado"
        return
    fi
    
    info "Instalando LocalSend desde AUR..."
    if yay -S --noconfirm localsend-bin; then
        success "LocalSend instalado"
        info "Abre LocalSend desde el menú de aplicaciones"
    else
        error "Fallo al instalar LocalSend"
    fi
}

install_emoji_launcher() {
    step "Instalando Emoji Launcher"
    
    local packages_needed=("rofi" "wl-clipboard")
    local to_install=()
    
    for pkg in "${packages_needed[@]}"; do
        if ! check_installed "$pkg"; then
            to_install+=("$pkg")
        fi
    done
    
    if [ ${#to_install[@]} -gt 0 ]; then
        info "Instalando dependencias..."
        sudo pacman -S --noconfirm --needed "${to_install[@]}"
    fi
    
    if ! command -v rofimoji &> /dev/null; then
        info "Instalando rofimoji..."
        yay -S --noconfirm rofimoji
    fi
    
    if [ -f "$HOME/.config/hypr/bindings.conf" ]; then
        if ! grep -q "rofimoji" "$HOME/.config/hypr/bindings.conf"; then
            cat >> "$HOME/.config/hypr/bindings.conf" << 'EOF'

# Emoji Launcher - SUPER+PERIOD
bindd = SUPER, PERIOD, Emoji Picker, exec, rofimoji
EOF
        fi
    fi
    
    success "Emoji launcher instalado (SUPER+.)"
}

install_epson_drivers() {
    step "Instalando drivers Epson L4150"
    
    info "Instalando drivers Epson..."
    yay -S --noconfirm epson-inkjet-printer-escpr epson-inkjet-printer-escpr2
    
    info "Instalando Epson Scan..."
    yay -S --noconfirm epsonscan2 || warning "epsonscan2 no disponible"
    
    info "Habilitando CUPS..."
    sudo systemctl enable --now cups.service
    sudo systemctl enable --now cups-browsed.service 2>/dev/null || true
    sudo usermod -aG lp "$USER"
    
    NEEDS_REBOOT=true
    
    success "Drivers Epson instalados"
    info "Configura en: http://localhost:631"
}

install_zerotier() {
    step "Instalando ZeroTier One"
    
    if command -v zerotier-cli &> /dev/null; then
        success "ZeroTier ya está instalado"
    else
        info "Instalando zerotier-one..."
        yay -S --noconfirm zerotier-one
        success "ZeroTier instalado"
    fi
    
    info "Habilitando servicio..."
    sudo systemctl enable --now zerotier-one.service
    
    NEEDS_REBOOT=true
    
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Configuración de ZeroTier Network${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if ask_yes_no "¿Conectarse a tu red ZeroTier?" "y"; then
        read -p "$(echo -e ${YELLOW}Network ID: ${NC})" ZEROTIER_NETWORK
        log "ZeroTier Network ID: $ZEROTIER_NETWORK"
        
        if [ ! -z "$ZEROTIER_NETWORK" ]; then
            info "Conectando..."
            sudo zerotier-cli join "$ZEROTIER_NETWORK"
            success "Solicitud enviada"
            warning "Autoriza en: https://my.zerotier.com"
            echo ""
            sudo zerotier-cli listnetworks
        fi
    fi
}

configure_gnome_keyring() {
    step "Configurando GNOME Keyring"
    
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Configuración de GNOME Keyring${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
    info "Guarda contraseñas de Git, VS Code, etc."
    echo ""
    
    if ask_yes_no "¿Configurar ahora?" "y"; then
        echo ""
        echo -e "${YELLOW}Opciones:${NC}"
        echo "  1. Sin contraseña (conveniente)"
        echo "  2. Contraseña de usuario (recomendado)"
        echo "  3. Personalizada"
        echo ""
        read -p "$(echo -e ${YELLOW}Selecciona [1/2/3]: ${NC})" keyring_option
        log "Keyring option: $keyring_option"
        
        case "$keyring_option" in
            2)
                echo ""
                info "Ingresa tu contraseña de usuario:"
                read -s KEYRING_PASSWORD
                echo ""
                ;;
            3)
                echo ""
                read -sp "$(echo -e ${YELLOW}Nueva contraseña: ${NC})" KEYRING_PASSWORD
                echo ""
                read -sp "$(echo -e ${YELLOW}Confirmar: ${NC})" keyring_confirm
                echo ""
                [ "$KEYRING_PASSWORD" != "$keyring_confirm" ] && KEYRING_PASSWORD=""
                ;;
            *)
                KEYRING_PASSWORD=""
                ;;
        esac
        
        info "Configurando PAM..."
        if ! grep -q "pam_gnome_keyring" /etc/pam.d/login 2>/dev/null; then
            echo "auth       optional     pam_gnome_keyring.so" | sudo tee -a /etc/pam.d/login > /dev/null
            echo "session    optional     pam_gnome_keyring.so auto_start" | sudo tee -a /etc/pam.d/login > /dev/null
        fi
        
        [ -f /etc/pam.d/sddm ] && ! grep -q "pam_gnome_keyring" /etc/pam.d/sddm && {
            echo "auth       optional     pam_gnome_keyring.so" | sudo tee -a /etc/pam.d/sddm > /dev/null
            echo "session    optional     pam_gnome_keyring.so auto_start" | sudo tee -a /etc/pam.d/sddm > /dev/null
        }
        
        eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh 2>/dev/null)
        export SSH_AUTH_SOCK GPG_AGENT_INFO GNOME_KEYRING_CONTROL GNOME_KEYRING_PID
        
        success "GNOME Keyring configurado"
    fi
}

# =============================================================================
# ZSH
# =============================================================================

install_oh_my_zsh() {
    step "Instalando Oh My Zsh"
    
    if [ -d "$HOME/.oh-my-zsh" ]; then
        success "Oh My Zsh ya está instalado"
        return
    fi
    
    info "Descargando..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    success "Oh My Zsh instalado"
}

install_zsh_plugins() {
    step "Instalando plugins de Zsh"
    
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    
    [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && \
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" --quiet
    
    [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && \
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" --quiet
    
    success "Plugins instalados"
}

install_oh_my_posh_theme() {
    step "Configurando tema Oh My Posh"
    
    mkdir -p ~/.poshthemes
    curl -fsSL https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/catppuccin.omp.json \
        -o ~/.poshthemes/catppuccin.omp.json
    
    success "Tema Catppuccin listo"
}

create_zshrc() {
    step "Creando configuración Zsh"
    
    [ -f "$HOME/.zshrc" ] && cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    
    cat > "$HOME/.zshrc" << 'ZSHRC_EOF'
# =============================================================================
#                    CONFIGURACIÓN ZSH - OMARCHY v2.1
# =============================================================================

# --- PATH --------------------------------------------------------------------
typeset -U PATH path
path=(
  $HOME/.local/bin
  $HOME/bin
  $HOME/.npm-global/bin
  $HOME/AppImages
  $HOME/go/bin
  $path
)

# --- Oh My Zsh ---------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

plugins=(
  git sudo history colorize
  docker docker-compose
  npm node python pip golang
  copypath copyfile
)

export ZSH_DISABLE_COMPFIX=true
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "$HOME/.zcompcache"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select

[ -r "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

[ -r "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
  source "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

[ -r "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \
  source "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# --- Oh My Posh --------------------------------------------------------------
if command -v oh-my-posh >/dev/null 2>&1; then
  if [ -f ~/.poshthemes/catppuccin.omp.json ]; then
    eval "$(oh-my-posh init zsh --config ~/.poshthemes/catppuccin.omp.json)"
  else
    eval "$(oh-my-posh init zsh)"
  fi
fi

# --- Go ----------------------------------------------------------------------
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"

# --- NVM ---------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# --- Python ------------------------------------------------------------------
alias pip='pip3'
alias python='python3'

venv() {
  case "$1" in
    create) python -m venv .venv && echo "✅ Entorno creado" ;;
    on|activate)
      [ -f ".venv/bin/activate" ] && . .venv/bin/activate && echo "🟢 Activado" || echo "❌ No encontrado" ;;
    off|deactivate)
      deactivate 2>/dev/null && echo "🔴 Desactivado" || echo "🤷 No activo" ;;
    *) echo "Uso: venv [create|on|off]" ;;
  esac
}

# --- Aliases -----------------------------------------------------------------
alias cls='clear'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# System info
alias ff='fastfetch'
alias nf='fastfetch'

# Arch
alias pacu='sudo pacman -Syu'
alias paci='sudo pacman -S'
alias pacr='sudo pacman -Rns'
alias pacs='pacman -Ss'
alias yayu='yay -Syu'
alias yayi='yay -S'

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias gcb='git checkout -b'
alias glog='git log --oneline --graph --decorate'
gac(){ git add . && git commit -m "$1"; }

# Docker
docker compose version >/dev/null 2>&1 && alias dc='docker compose' || alias dc='docker-compose'
alias d='docker'
alias dps='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlog='docker logs -f'

# NPM
alias nrs='npm run start'
alias nrd='npm run dev'
alias nrb='npm run build'
alias nrt='npm run test'
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install -g'

# Python
alias py='python'
alias pir='pip install -r requirements.txt'
alias pipi='pip install'
alias pipf='pip freeze > requirements.txt'

# ZeroTier
alias zt='sudo zerotier-cli'
alias ztstatus='sudo zerotier-cli listnetworks'
alias ztinfo='sudo zerotier-cli info'

alias clima='curl wttr.in/Saltillo'

# --- Funciones ---------------------------------------------------------------
mkcd(){ mkdir -p "$1" && cd "$1"; }

extract(){
  [ ! -f "$1" ] && echo "No es un archivo" && return 1
  case "$1" in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz) tar xzf "$1" ;;
    *.bz2) bunzip2 "$1" ;;
    *.rar) unrar e "$1" ;;
    *.gz) gunzip "$1" ;;
    *.tar) tar xf "$1" ;;
    *.tbz2) tar xjf "$1" ;;
    *.tgz) tar xzf "$1" ;;
    *.zip) unzip "$1" ;;
    *.Z) uncompress "$1" ;;
    *.7z) 7z x "$1" ;;
    *) echo "No se puede extraer '$1'" ;;
  esac
}

killport(){
  [ $# -eq 0 ] && echo "Uso: killport <puerto>" && return 1
  local pid=$(lsof -ti:"$1" 2>/dev/null)
  [ -n "$pid" ] && kill -9 "$pid" && echo "✅ Eliminado" || echo "🤷 No encontrado"
}

serve(){ python -m http.server "${1:-8000}"; }

# --- yt-dlp MEJORADO ---------------------------------------------------------
export YTDLP_DIR="$HOME/Videos/YouTube"
mkdir -p "$YTDLP_DIR"/{Music,Videos}

ytm() {
  case "$1" in
    -h|--help|'') 
      echo "🎵 ytm <URL|búsqueda> - MP3 320kbps"
      echo "Ejemplos:"
      echo "  ytm https://youtu.be/..."
      echo "  ytm 'nombre canción'"
      return 0 
      ;;
  esac
  
  local out="$YTDLP_DIR/Music/%(title).180s.%(ext)s"
  local opts=(
    --extract-audio --audio-format mp3 --audio-quality 320K
    --embed-metadata --embed-thumbnail --convert-thumbnails jpg
    --no-playlist --retries 10 --fragment-retries 10
    --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
    --extractor-args "youtube:player_client=android,web"
    --progress --newline -o "$out"
  )
  
  if [[ "$1" == http* ]]; then
    echo "📥 Descargando audio..."
    yt-dlp "${opts[@]}" "$@"
  else
    echo "🔍 Buscando: $*"
    yt-dlp "${opts[@]}" "ytsearch1:$*"
  fi
  
  [ $? -eq 0 ] && echo "✅ En: $YTDLP_DIR/Music/"
}

ytv() {
  case "$1" in
    -h|--help|'') 
      echo "🎬 ytv <URL|búsqueda> [calidad]"
      echo "Calidades: 1080, 720, 480 (default: best)"
      return 0 
      ;;
  esac
  
  local quality="${2:-best}"
  local out="$YTDLP_DIR/Videos/%(title).180s.%(ext)s"
  
  local fmt
  case "$quality" in
    1080) fmt='bv*[height<=1080][ext=mp4]+ba/b[height<=1080]' ;;
    720)  fmt='bv*[height<=720][ext=mp4]+ba/b[height<=720]' ;;
    480)  fmt='bv*[height<=480][ext=mp4]+ba/b[height<=480]' ;;
    *)    fmt='bv*[ext=mp4]+ba/b[ext=mp4]/b' ;;
  esac
  
  local opts=(
    -f "$fmt" --embed-metadata --embed-thumbnail
    --embed-subs --sub-langs "es.*,en.*" --convert-thumbnails jpg
    --no-playlist --retries 10 --fragment-retries 10
    --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
    --extractor-args "youtube:player_client=android,web"
    --progress --newline -o "$out"
  )
  
  if [[ "$1" == http* ]]; then
    echo "📥 Descargando video..."
    yt-dlp "${opts[@]}" "$1"
  else
    echo "🔍 Buscando: $1"
    yt-dlp "${opts[@]}" "ytsearch1:$1"
  fi
  
  [ $? -eq 0 ] && echo "✅ En: $YTDLP_DIR/Videos/"
}

ytls() {
  echo "🎵 Music:"
  ls -1t "$YTDLP_DIR/Music" 2>/dev/null | head -5 | sed 's/^/  /' || echo "  (vacío)"
  echo ""
  echo "🎬 Videos:"
  ls -1t "$YTDLP_DIR/Videos" 2>/dev/null | head -5 | sed 's/^/  /' || echo "  (vacío)"
}

# --- GNOME Keyring -----------------------------------------------------------
if [ -n "$DESKTOP_SESSION" ]; then
  if ! pgrep -u "$USER" gnome-keyring-daemon > /dev/null 2>&1; then
    eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh 2>/dev/null)
  fi
  export SSH_AUTH_SOCK GPG_AGENT_INFO GNOME_KEYRING_CONTROL GNOME_KEYRING_PID
fi

# --- SSH Agent ---------------------------------------------------------------
# Iniciar ssh-agent si no está corriendo
if [ -z "$SSH_AUTH_SOCK" ]; then
  # Directorio para el socket del agente
  export SSH_AGENT_DIR="$HOME/.ssh/agent"
  mkdir -p "$SSH_AGENT_DIR"
  
  # Archivo para guardar info del agente
  SSH_ENV="$SSH_AGENT_DIR/env"
  
  # Función para iniciar el agente
  start_agent() {
    echo "🔑 Iniciando ssh-agent..."
    ssh-agent > "$SSH_ENV"
    chmod 600 "$SSH_ENV"
    . "$SSH_ENV" > /dev/null
  }
  
  # Verificar si hay un agente corriendo
  if [ -f "$SSH_ENV" ]; then
    . "$SSH_ENV" > /dev/null
    # Verificar si el proceso del agente existe
    ps -p $SSH_AGENT_PID > /dev/null 2>&1 || start_agent
  else
    start_agent
  fi
  
  # Agregar llaves SSH automáticamente (detectar todas las llaves privadas)
  if [ -d "$HOME/.ssh" ]; then
    # Buscar todas las llaves privadas (excluir .pub, known_hosts, config, etc)
    for key in "$HOME/.ssh"/*; do
      # Verificar que sea archivo regular, no .pub, y sea llave SSH válida
      if [ -f "$key" ] && [[ ! "$key" =~ \.pub$ ]] && \
         [[ ! "$key" =~ known_hosts ]] && [[ ! "$key" =~ authorized_keys ]] && \
         [[ ! "$key" =~ config ]] && [[ ! "$key" =~ agent ]]; then
        # Verificar que sea llave SSH válida
        if ssh-keygen -l -f "$key" &>/dev/null; then
          # Verificar si ya está cargada
          local key_fingerprint=$(ssh-keygen -lf "$key" 2>/dev/null | awk '{print $2}')
          if ! ssh-add -l 2>/dev/null | grep -q "$key_fingerprint"; then
            if ssh-add "$key" 2>/dev/null; then
              echo "✅ Llave agregada: $(basename $key)"
            fi
          fi
        fi
      fi
    done
  fi
fi

# Alias útiles para SSH
alias ssh-list='ssh-add -l'                    # Listar llaves cargadas
alias ssh-clear='ssh-add -D'                   # Limpiar todas las llaves
alias ssh-reload='                             # Recargar todas las llaves
  ssh-add -D 2>/dev/null
  for key in ~/.ssh/*; do
    if [ -f "$key" ] && [[ ! "$key" =~ \.pub$ ]] && ssh-keygen -l -f "$key" &>/dev/null; then
      ssh-add "$key" 2>/dev/null && echo "✅ $(basename $key)"
    fi
  done
'

alias ssh-github='ssh -T git@github.com'       # Test GitHub

# --- zoxide ------------------------------------------------------------------
# Reemplazo inteligente de cd
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
  
  # Alias para compatibilidad
  alias cd='z'
  alias cdi='zi'                               # Interactive mode
  alias zz='z -'                               # Ir al directorio anterior
fi

# --- Historial ---------------------------------------------------------------
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE AUTO_CD EXTENDED_GLOB
stty -ixon 2>/dev/null
export LESS='-R'

# --- Funciones externas ------------------------------------------------------
[ -d "$HOME/.zsh_functions" ] || mkdir -p "$HOME/.zsh_functions"
for func_file in "$HOME/.zsh_functions"/*.zsh(N); do
  source "$func_file"
done

# --- Local -------------------------------------------------------------------
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
ZSHRC_EOF

    success ".zshrc creado"
}

# =============================================================================
# CONFIGURACIÓN
# =============================================================================

configure_permissions() {
    step "Configurando permisos"
    
    sudo usermod -aG docker,video,input,lp "$USER"
    sudo chmod +s /usr/bin/brightnessctl 2>/dev/null || true
    
    sudo tee /etc/udev/rules.d/90-backlight.rules > /dev/null << 'EOF'
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
EOF
    
    sudo udevadm control --reload-rules 2>/dev/null || true
    
    success "Permisos configurados"
}

configure_git() {
    step "Configurando Git"
    
    git config --global user.name &> /dev/null && success "Git ya configurado" && return
    
    echo ""
    if ask_yes_no "¿Configurar Git?" "y"; then
        read -p "$(echo -e ${YELLOW}Nombre: ${NC})" git_name
        read -p "$(echo -e ${YELLOW}Email: ${NC})" git_email
        log "Git config: $git_name <$git_email>"
        
        git config --global user.name "$git_name"
        git config --global user.email "$git_email"
        git config --global credential.helper libsecret
        git config --global init.defaultBranch main
        
        success "Git configurado"
    fi
}

configure_ssh() {
    step "Configurando SSH"
    
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Configuración de SSH${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Escanear llaves SSH existentes
    info "Escaneando ~/.ssh/ en busca de llaves privadas..."
    local ssh_keys=()
    local key_names=()
    
    for key in ~/.ssh/*; do
        if [ -f "$key" ] && [[ ! "$key" =~ \.pub$ ]] && [[ ! "$key" =~ known_hosts ]] && \
           [[ ! "$key" =~ authorized_keys ]] && [[ ! "$key" =~ config ]] && [[ ! "$key" =~ agent ]]; then
            if ssh-keygen -l -f "$key" &>/dev/null; then
                ssh_keys+=("$key")
                key_names+=("$(basename $key)")
            fi
        fi
    done
    
    # Si no hay llaves, mostrar guía
    if [ ${#ssh_keys[@]} -eq 0 ]; then
        warning "No se encontraron llaves SSH en ~/.ssh/"
        echo ""
        echo -e "${YELLOW}Para usar SSH necesitas primero importar o generar llaves.${NC}"
        echo ""
        echo -e "${CYAN}Opciones:${NC}"
        echo ""
        echo -e "${BOLD}1. Generar nueva llave SSH:${NC}"
        echo "   ssh-keygen -t ed25519 -C 'tu@email.com' -f ~/.ssh/mi_llave"
        echo ""
        echo -e "${BOLD}2. Importar llaves existentes:${NC}"
        echo "   - Copia tus llaves a ~/.ssh/"
        echo "   - Ajusta permisos: chmod 600 ~/.ssh/*"
        echo "   - Ejemplo: scp usuario@otro-pc:~/.ssh/id_github ~/.ssh/"
        echo ""
        echo -e "${BOLD}3. Configurar después:${NC}"
        echo "   Ejecuta: bash omarchy-setup.sh --ssh"
        echo ""
        
        if ask_yes_no "¿Quieres generar una nueva llave SSH ahora?" "n"; then
            echo ""
            read -p "$(echo -e ${YELLOW}Email/Comentario: ${NC})" ssh_email
            read -p "$(echo -e ${YELLOW}Nombre de archivo [id_ed25519]: ${NC})" ssh_filename
            ssh_filename=${ssh_filename:-id_ed25519}
            
            info "Generando llave SSH..."
            ssh-keygen -t ed25519 -C "${ssh_email:-$(whoami)@$(hostname)}" -f ~/.ssh/$ssh_filename
            
            success "Llave generada: ~/.ssh/$ssh_filename"
            echo ""
            echo -e "${YELLOW}Llave pública (comparte esta):${NC}"
            cat ~/.ssh/$ssh_filename.pub
            echo ""
            warning "Vuelve a ejecutar el script para configurar SSH"
        else
            info "Configuración SSH saltada"
            info "Ejecuta cuando tengas llaves: bash omarchy-setup.sh --ssh"
        fi
        
        # Crear config mínimo
        if [ ! -f ~/.ssh/config ]; then
            cat > ~/.ssh/config << 'EOF'
# SSH CONFIG

Host *
    AddKeysToAgent yes
    IdentitiesOnly yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF
            chmod 600 ~/.ssh/config
        fi
        
        mkdir -p ~/.ssh/agent
        chmod 700 ~/.ssh/agent
        
        return
    fi
    
    # Si hay llaves, mostrar y confirmar
    success "Encontradas ${#ssh_keys[@]} llaves SSH:"
    echo ""
    for i in "${!key_names[@]}"; do
        local fingerprint=$(ssh-keygen -l -f "${ssh_keys[$i]}" | awk '{print $2}')
        local key_type=$(ssh-keygen -l -f "${ssh_keys[$i]}" | awk '{print $4}')
        echo "  $((i+1)). ${CYAN}${key_names[$i]}${NC}"
        echo "     Fingerprint: $fingerprint"
        echo "     Tipo: $key_type"
        echo ""
    done
    
    if ! ask_yes_no "¿Son estas tus llaves correctas?" "y"; then
        warning "Verifica tus llaves en ~/.ssh/"
        info "Ejecuta después: bash omarchy-setup.sh --ssh"
        return
    fi
    
    echo ""
    if ! ask_yes_no "¿Configurar SSH config con estas llaves?" "y"; then
        info "Saltando configuración SSH"
        info "Puedes configurar después: bash omarchy-setup.sh --ssh"
        return
    fi
    
    # Backup del config existente
    if [ -f ~/.ssh/config ]; then
        cp ~/.ssh/config ~/.ssh/config.backup.$(date +%Y%m%d_%H%M%S)
        info "Backup creado: ~/.ssh/config.backup.*"
    fi
    
    # Crear config base
    cat > ~/.ssh/config << EOF
# ===============================
# SSH CONFIG - Omarchy Setup
# ===============================
# Generado: $(date '+%Y-%m-%d %H:%M:%S')

# Configuración global
Host *
    AddKeysToAgent yes
    IdentitiesOnly yes
    ServerAliveInterval 60
    ServerAliveCountMax 3

EOF
    
    # Configurar cada llave interactivamente
    echo ""
    echo -e "${YELLOW}Configuración interactiva de llaves SSH${NC}"
    echo "Presiona Enter para saltar cualquier llave"
    echo ""
    
    local configured_count=0
    
    for i in "${!ssh_keys[@]}"; do
        local key_file="${ssh_keys[$i]}"
        local key_name="${key_names[$i]}"
        
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}Llave $((i+1))/${#ssh_keys[@]}: $key_name${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        if ! ask_yes_no "  ¿Configurar esta llave?" "y"; then
            info "  Saltando $key_name"
            continue
        fi
        
        # Pedir información del host
        local host_alias=""
        local hostname=""
        local username=""
        
        read -p "$(echo -e ${YELLOW}  Alias del host \(ej: github, vps, raspberry\): ${NC})" host_alias        
        if [ -z "$host_alias" ]; then
            warning "  Sin alias, saltando..."
            continue
        fi
        
        read -p "$(echo -e ${YELLOW}  Hostname/IP: ${NC})" hostname
        read -p "$(echo -e ${YELLOW}  Usuario: ${NC})" username
        
        # Agregar al config
        {
            echo ""
            echo "# $host_alias"
            echo "Host $host_alias"
            [ -n "$hostname" ] && echo "    HostName $hostname"
            [ -n "$username" ] && echo "    User $username"
            echo "    IdentityFile $key_file"
        } >> ~/.ssh/config
        
        log "SSH host configured: $host_alias -> $hostname (key: $key_name)"
        success "  ✓ Configurado: $host_alias"
        configured_count=$((configured_count + 1))
    done
    
    chmod 600 ~/.ssh/config
    
    # Crear directorio del agente
    mkdir -p ~/.ssh/agent
    chmod 700 ~/.ssh/agent
    
    echo ""
    success "SSH configurado ($configured_count hosts)"
    echo ""
    info "Comandos disponibles:"
    echo "  ssh-list      - Ver llaves cargadas"
    echo "  ssh-clear     - Limpiar todas"
    echo "  ssh-reload    - Recargar llaves"
    
    if [ $configured_count -gt 0 ]; then
        echo ""
        info "Conexiones SSH configuradas:"
        grep "^Host " ~/.ssh/config | grep -v "Host \*" | while read -r line; do
            local host=$(echo $line | awk '{print $2}')
            echo "  ssh $host"
        done
    fi
    
    echo ""
    info "Edita manualmente: nano ~/.ssh/config"
}

configure_npm() {
    step "Configurando NPM"
    
    mkdir -p ~/.npm-global
    npm config set prefix '~/.npm-global'
    
    success "NPM configurado"
}

setup_directories() {
    step "Creando directorios"
    
    mkdir -p ~/AppImages ~/Videos/YouTube/{Music,Videos} ~/Projects ~/.zsh_functions ~/go/{bin,src,pkg}
    gsettings set org.gnome.nautilus.preferences show-image-thumbnails 'always' 2>/dev/null || true
    
    success "Directorios creados"
}

set_default_shell() {
    step "Configurando Zsh"
    
    [ "$SHELL" == "$(which zsh)" ] && success "Zsh ya es el shell" && return
    
    chsh -s $(which zsh)
    NEEDS_REBOOT=true
    success "Zsh configurado"
}

# =============================================================================
# MAIN
# =============================================================================

# Mostrar ayuda
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}${BOLD}          OMARCHY ZSH SETUP v2.1 - Ayuda${NC}                     ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}Uso:${NC}"
    echo "  bash omarchy-setup.sh          # Instalación completa"
    echo "  bash omarchy-setup.sh --ssh    # Solo configurar SSH"
    echo "  bash omarchy-setup.sh --help   # Mostrar esta ayuda"
    echo ""
    echo -e "${BOLD}Instalación completa incluye:${NC}"
    echo "  • Zsh + Oh My Zsh + Oh My Posh (tema Catppuccin)"
    echo "  • zoxide (cd inteligente)"
    echo "  • Google Chrome"
    echo "  • LocalSend"
    echo "  • Drivers Epson L4150 + Scan"
    echo "  • ZeroTier One"
    echo "  • Emoji Launcher (SUPER+.)"
    echo "  • GNOME Keyring + SSH Agent automático"
    echo "  • Go, Git, Docker, Node, Python, yt-dlp"
    echo ""
    echo -e "${BOLD}Modo --ssh:${NC}"
    echo "  Configura SSH de forma interactiva:"
    echo "  • Escanea llaves en ~/.ssh/"
    echo "  • Genera ~/.ssh/config"
    echo "  • Configura ssh-agent automático"
    echo ""
    echo -e "${BOLD}Logs:${NC}"
    echo "  ~/omarchy-setup.log       # Log completo"
    echo "  ~/omarchy-errors.log      # Solo errores"
    echo ""
    echo -e "${BOLD}GitHub:${NC} https://github.com/marcogll/scripts_mg"
    echo ""
    exit 0
fi

# Modo SSH-only
if [ "$1" == "--ssh" ]; then
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}${BOLD}     OMARCHY SSH SETUP - Solo configuración SSH${NC}              ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    setup_logging
    
    CURRENT_STEP=0
    TOTAL_STEPS=1
    
    configure_ssh
    
    echo ""
    echo -e "${GREEN}✓ Configuración SSH completada${NC}"
    echo ""
    info "Logs: $LOG_FILE"
    echo ""
    exit 0
fi

main() {
    setup_logging
    print_header
    
    echo -e "${BOLD}Este script instalará:${NC}"
    echo ""
    echo "  • Zsh + Oh My Zsh + Oh My Posh (Catppuccin)"
    echo "  • zoxide (cd inteligente)"
    echo "  • Google Chrome (remueve omarchy-chromium)"
    echo "  • LocalSend (compartir archivos)"
    echo "  • Drivers Epson L4150 + Scan"
    echo "  • ZeroTier One"
    echo "  • Emoji Launcher (SUPER+.)"
    echo "  • GNOME Keyring + SSH Agent"
    echo "  • Go, Git, Docker, Node, Python, yt-dlp"
    echo ""
    
    ask_yes_no "¿Continuar?" "y" || { info "Cancelado"; exit 0; }
    
    echo ""
    check_requirements
    
    install_packages
    install_yay
    install_oh_my_posh
    install_google_chrome
    install_localsend
    install_emoji_launcher
    install_epson_drivers
    install_zerotier
    configure_gnome_keyring
    install_oh_my_zsh
    install_zsh_plugins
    install_oh_my_posh_theme
    create_zshrc
    configure_permissions
    configure_git
    configure_ssh
    configure_npm
    setup_directories
    set_default_shell
    
    echo ""
    log "==================================================================="
    log "INSTALACIÓN COMPLETADA - $(date '+%Y-%m-%d %H:%M:%S')"
    log "==================================================================="
    echo -e "${GREEN}✓✓✓ Instalación completada ✓✓✓${NC}"
    echo ""
    echo -e "${CYAN}📋 Logs guardados en:${NC}"
    echo -e "   ${BOLD}$LOG_FILE${NC}"
    echo -e "   ${BOLD}$ERROR_LOG${NC}"
    echo ""
    
    if [ "$NEEDS_REBOOT" = true ]; then
        echo -e "${YELLOW}╔════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║${NC}  ${BOLD}REINICIO REQUERIDO${NC}                      ${YELLOW}║${NC}"
        echo -e "${YELLOW}╚════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${CYAN}Cambios que requieren reinicio:${NC}"
        echo "  • Grupos de usuario (docker, lp, video)"
        echo "  • Servicios (CUPS, ZeroTier)"
        echo "  • Shell predeterminado (Zsh)"
        echo ""
        
        if ask_yes_no "¿Reiniciar ahora?" "y"; then
            echo ""
            info "Reiniciando en 3 segundos..."
            sleep 3
            sudo reboot
        else
            warning "Recuerda reiniciar manualmente"
        fi
    else
        echo -e "${CYAN}Próximos pasos:${NC}"
        echo "  1. Cierra esta terminal"
        echo "  2. Abre una nueva"
        echo "  3. Ejecuta: source ~/.zshrc"
    fi
    
    echo ""
    [ ! -z "$ZEROTIER_NETWORK" ] && echo -e "${YELLOW}⚠${NC}  Autoriza en: https://my.zerotier.com"
    echo ""
}

main "$@"
