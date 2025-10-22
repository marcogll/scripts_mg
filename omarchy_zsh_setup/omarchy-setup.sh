#!/bin/bash

# =============================================================================
#                   OMARCHY ZSH SETUP SCRIPT
# =============================================================================
# GitHub: https://github.com/marcogll/scripts_mg
# Instalación: bash <(curl -fsSL https://raw.githubusercontent.com/marcogll/scripts_mg/main/omarchy_zsh_setup/omarchy-setup.sh)
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

TOTAL_STEPS=16
CURRENT_STEP=0
ZEROTIER_NETWORK=""
KEYRING_PASSWORD=""

# =============================================================================
# FUNCIONES AUXILIARES
# =============================================================================

print_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}${BOLD}          OMARCHY ZSH SETUP - Configuración Completa${NC}          ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
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
    echo -e "${GREEN}[${CURRENT_STEP}/${TOTAL_STEPS}]${NC} ${BOLD}$1${NC}"
    progress_bar $CURRENT_STEP $TOTAL_STEPS "$1"
    echo ""
}

success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${CYAN}ℹ${NC} $1"; }

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
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Por favor responde sí (y) o no (n).";;
        esac
    done
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
        "oh-my-posh"
        "python" "python-pip" "python-virtualenv"
        "nodejs" "npm"
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
        "neofetch" "htop" "btop" "tree" "unzip" "p7zip" "unrar"
    )
    
    info "Actualizando sistema..."
    sudo pacman -Sy --noconfirm
    
    info "Instalando ${#packages[@]} paquetes..."
    for pkg in "${packages[@]}"; do
        sudo pacman -S --noconfirm --needed "$pkg" 2>&1 | grep -v "warning:" || true
    done
    
    success "Paquetes instalados"
}

install_yay() {
    step "Instalando yay (AUR helper)"
    
    if command -v yay &> /dev/null; then
        success "yay ya está instalado"
        return
    fi
    
    info "Clonando yay..."
    cd /tmp
    rm -rf yay
    git clone https://aur.archlinux.org/yay.git --quiet
    cd yay
    
    info "Compilando yay..."
    makepkg -si --noconfirm
    cd ~
    
    success "yay instalado"
}

install_google_chrome() {
    step "Instalando Google Chrome"
    
    if pacman -Q omarchy-chromium &> /dev/null; then
        info "Removiendo omarchy-chromium..."
        sudo pacman -Rns --noconfirm omarchy-chromium 2>/dev/null || true
    fi
    
    if pacman -Q chromium &> /dev/null; then
        info "Removiendo chromium..."
        sudo pacman -Rns --noconfirm chromium 2>/dev/null || true
    fi
    
    if command -v google-chrome-stable &> /dev/null; then
        success "Google Chrome ya está instalado"
    else
        info "Instalando Google Chrome desde AUR..."
        yay -S --noconfirm google-chrome
        success "Google Chrome instalado"
    fi
}

install_emoji_launcher() {
    step "Instalando Emoji Launcher"
    
    info "Instalando rofi y emoji selector..."
    sudo pacman -S --noconfirm --needed rofi wl-clipboard
    yay -S --noconfirm rofimoji
    
    if [ -f "$HOME/.config/hypr/bindings.conf" ]; then
        if ! grep -q "rofimoji" "$HOME/.config/hypr/bindings.conf"; then
            info "Agregando keybinding..."
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
    
    info "Instalando drivers desde AUR..."
    yay -S --noconfirm epson-inkjet-printer-escpr epson-inkjet-printer-escpr2
    
    info "Habilitando CUPS..."
    sudo systemctl enable --now cups.service
    sudo systemctl enable --now cups-browsed.service 2>/dev/null || true
    sudo usermod -aG lp "$USER"
    
    success "Drivers Epson instalados"
    info "Configura en: http://localhost:631"
}

install_zerotier() {
    step "Instalando ZeroTier One"
    
    if command -v zerotier-cli &> /dev/null; then
        success "ZeroTier ya está instalado"
    else
        info "Instalando desde AUR..."
        yay -S --noconfirm zerotier-one
        success "ZeroTier instalado"
    fi
    
    info "Habilitando servicio..."
    sudo systemctl enable --now zerotier-one.service
    
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Configuración de ZeroTier Network${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if ask_yes_no "¿Conectarse a tu red ZeroTier ahora?" "y"; then
        read -p "$(echo -e ${YELLOW}Network ID: ${NC})" ZEROTIER_NETWORK
        
        if [ ! -z "$ZEROTIER_NETWORK" ]; then
            info "Conectando a $ZEROTIER_NETWORK..."
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
    info "El keyring permite guardar contraseñas de Git, VS Code, etc."
    echo ""
    
    if ask_yes_no "¿Configurar GNOME Keyring ahora?" "y"; then
        echo ""
        echo -e "${YELLOW}Opciones de contraseña:${NC}"
        echo "  1. Sin contraseña (más conveniente, menos seguro)"
        echo "  2. Igual a tu contraseña de usuario (recomendado)"
        echo "  3. Contraseña personalizada"
        echo ""
        read -p "$(echo -e ${YELLOW}Selecciona opción [1/2/3]: ${NC})" keyring_option
        
        case "$keyring_option" in
            1)
                KEYRING_PASSWORD=""
                info "Keyring sin contraseña (desbloqueo automático)"
                ;;
            2)
                echo ""
                info "Ingresa tu contraseña de usuario de Linux:"
                read -s KEYRING_PASSWORD
                echo ""
                ;;
            3)
                echo ""
                read -sp "$(echo -e ${YELLOW}Nueva contraseña para keyring: ${NC})" KEYRING_PASSWORD
                echo ""
                read -sp "$(echo -e ${YELLOW}Confirma contraseña: ${NC})" keyring_confirm
                echo ""
                
                if [ "$KEYRING_PASSWORD" != "$keyring_confirm" ]; then
                    warning "Las contraseñas no coinciden, usando sin contraseña"
                    KEYRING_PASSWORD=""
                fi
                ;;
            *)
                KEYRING_PASSWORD=""
                ;;
        esac
        
        # Configurar PAM para auto-unlock
        info "Configurando PAM..."
        if ! grep -q "pam_gnome_keyring" /etc/pam.d/login; then
            echo "auth       optional     pam_gnome_keyring.so" | sudo tee -a /etc/pam.d/login > /dev/null
            echo "session    optional     pam_gnome_keyring.so auto_start" | sudo tee -a /etc/pam.d/login > /dev/null
        fi
        
        # Configurar para SDDM si existe
        if [ -f /etc/pam.d/sddm ]; then
            if ! grep -q "pam_gnome_keyring" /etc/pam.d/sddm; then
                echo "auth       optional     pam_gnome_keyring.so" | sudo tee -a /etc/pam.d/sddm > /dev/null
                echo "session    optional     pam_gnome_keyring.so auto_start" | sudo tee -a /etc/pam.d/sddm > /dev/null
            fi
        fi
        
        # Iniciar daemon
        info "Iniciando gnome-keyring-daemon..."
        eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh 2>/dev/null)
        export SSH_AUTH_SOCK GPG_AGENT_INFO GNOME_KEYRING_CONTROL GNOME_KEYRING_PID
        
        success "GNOME Keyring configurado"
        echo ""
        info "Configuración adicional:"
        echo "  1. Abre Seahorse (Contraseñas y claves)"
        echo "  2. Click en keyring 'Login'"
        echo "  3. Cambia contraseña si es necesario"
        echo ""
    else
        info "Puedes configurarlo después con: seahorse"
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
    
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" --quiet
    fi
    
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" --quiet
    fi
    
    success "Plugins instalados"
}

install_oh_my_posh_theme() {
    step "Configurando Oh My Posh"
    
    mkdir -p ~/.poshthemes
    curl -fsSL https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/catppuccin.omp.json \
        -o ~/.poshthemes/catppuccin.omp.json
    
    success "Tema Catppuccin configurado"
}

create_zshrc() {
    step "Creando configuración de Zsh"
    
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    cat > "$HOME/.zshrc" << 'ZSHRC_EOF'
# =============================================================================
#                         MI CONFIGURACIÓN ZSH (OMARCHY)
# =============================================================================

# --- PATH --------------------------------------------------------------------
typeset -U PATH path
path=(
  $HOME/.local/bin
  $HOME/bin
  $HOME/.npm-global/bin
  $HOME/AppImages
  $path
)

# --- Oh My Zsh ---------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

plugins=(
  git sudo history colorize
  docker docker-compose
  npm node python pip
  copypath copyfile
)

export ZSH_DISABLE_COMPFIX=true
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "$HOME/.zcompcache"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select

if [ -r "$ZSH/oh-my-zsh.sh" ]; then
  source "$ZSH/oh-my-zsh.sh"
fi

if [ -r "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
if [ -r "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# --- Oh My Posh --------------------------------------------------------------
if command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init zsh --config ~/.poshthemes/catppuccin.omp.json)"
fi

# --- NVM ---------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# --- Python ------------------------------------------------------------------
alias pip='pip3'
alias python='python3'

venv() {
  case "$1" in
    create) python -m venv .venv && echo "✅ Entorno virtual creado" ;;
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
if docker compose version >/dev/null 2>&1; then
  alias dc='docker compose'
else
  alias dc='docker-compose'
fi
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
  if [ -f "$1" ]; then
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
      *) echo "'$1' no se puede extraer" ;;
    esac
  fi
}

killport(){
  if [ $# -eq 0 ]; then echo "Uso: killport <puerto>"; return 1; fi
  local pid=$(lsof -ti:"$1" 2>/dev/null)
  [ -n "$pid" ] && kill -9 "$pid" && echo "✅ Eliminado" || echo "🤷 No encontrado"
}

serve(){ python -m http.server "${1:-8000}"; }

# --- yt-dlp ------------------------------------------------------------------
export YTDLP_DIR="$HOME/Videos/ytdlp"
[[ -d "$YTDLP_DIR" ]] || mkdir -p "$YTDLP_DIR"

ytm() {
  case "$1" in
    -h|--help|'') echo "🎵 ytm <URL|búsqueda>"; return 0 ;;
  esac
  local out="$YTDLP_DIR/%(title).200s [%(id)s].%(ext)s"
  if [[ "$1" == http* ]]; then
    yt-dlp -x --audio-format mp3 --audio-quality 320K --embed-metadata --embed-thumbnail --convert-thumbnails jpg -o "$out" "$@"
  else
    yt-dlp -x --audio-format mp3 --audio-quality 320K --embed-metadata --embed-thumbnail --convert-thumbnails jpg -o "$out" "ytsearch1:$*"
  fi
}

ytv() {
  case "$1" in
    -h|--help|'') echo "🎬 ytv <URL|búsqueda>"; return 0 ;;
  esac
  local out="$YTDLP_DIR/%(title).200s [%(id)s].%(ext)s"
  local fmt='bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/b'
  if [[ "$1" == http* ]]; then
    yt-dlp -f "$fmt" --embed-metadata --embed-thumbnail --convert-thumbnails jpg -o "$out" "$@"
  else
    yt-dlp -f "$fmt" --embed-metadata --embed-thumbnail --convert-thumbnails jpg -o "$out" "ytsearch1:$*"
  fi
}

# --- GNOME Keyring -----------------------------------------------------------
if [ -n "$DESKTOP_SESSION" ]; then
  if ! pgrep -u "$USER" gnome-keyring-daemon > /dev/null 2>&1; then
    eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh 2>/dev/null)
  fi
  export SSH_AUTH_SOCK GPG_AGENT_INFO GNOME_KEYRING_CONTROL GNOME_KEYRING_PID
fi

# --- Historial ---------------------------------------------------------------
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE AUTO_CD EXTENDED_GLOB
stty -ixon
export LESS='-R'

# --- Funciones externas ------------------------------------------------------
[[ ! -d "$HOME/.zsh_functions" ]] && mkdir -p "$HOME/.zsh_functions"
for func_file in "$HOME/.zsh_functions"/*.zsh(N); do
  source "$func_file"
done
unset func_file

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
    sudo udevadm trigger 2>/dev/null || true
    
    success "Permisos configurados"
}

configure_git() {
    step "Configurando Git"
    
    if git config --global user.name &> /dev/null; then
        success "Git ya configurado"
        return
    fi
    
    echo ""
    if ask_yes_no "¿Configurar Git ahora?" "y"; then
        read -p "$(echo -e ${YELLOW}Nombre: ${NC})" git_name
        read -p "$(echo -e ${YELLOW}Email: ${NC})" git_email
        
        git config --global user.name "$git_name"
        git config --global user.email "$git_email"
        git config --global credential.helper libsecret
        git config --global init.defaultBranch main
        
        success "Git configurado"
    fi
}

configure_npm() {
    step "Configurando NPM"
    
    mkdir -p ~/.npm-global
    npm config set prefix '~/.npm-global'
    
    success "NPM configurado"
}

setup_directories() {
    step "Creando directorios"
    
    mkdir -p ~/AppImages ~/Videos/ytdlp ~/Projects ~/.zsh_functions
    gsettings set org.gnome.nautilus.preferences show-image-thumbnails 'always' 2>/dev/null || true
    
    success "Directorios creados"
}

set_default_shell() {
    step "Configurando Zsh como shell predeterminado"
    
    if [ "$SHELL" == "$(which zsh)" ]; then
        success "Zsh ya es el shell predeterminado"
        return
    fi
    
    chsh -s $(which zsh)
    success "Zsh configurado"
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    print_header
    
    echo -e "${BOLD}Este script instalará:${NC}"
    echo ""
    echo "  • Zsh + Oh My Zsh + Oh My Posh"
    echo "  • Google Chrome (remueve omarchy-chromium)"
    echo "  • Drivers Epson L4150"
    echo "  • ZeroTier One"
    echo "  • Emoji Launcher (SUPER+.)"
    echo "  • GNOME Keyring (para Git/VS Code)"
    echo "  • Git, Docker, Node.js, Python, yt-dlp"
    echo ""
    
    if ! ask_yes_no "¿Continuar?" "y"; then
        info "Instalación cancelada"
        exit 0
    fi
    
    echo ""
    check_requirements
    
    install_packages
    install_yay
    install_google_chrome
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
    configure_npm
    setup_directories
    set_default_shell
    
    echo ""
    echo -e "${GREEN}✓ Instalación completada${NC}"
    echo ""
    echo -e "${YELLOW}Próximos pasos:${NC}"
    echo "  1. Cierra sesión y vuelve a entrar"
    echo "  2. Abre nueva terminal"
    echo "  3. Ejecuta: source ~/.zshrc"
    echo ""
    
    [ ! -z "$ZEROTIER_NETWORK" ] && echo -e "${YELLOW}⚠${NC}  Autoriza en: https://my.zerotier.com" && echo ""
}

main "$@"
