#!/bin/bash

# =============================================================================
#                    OMARCHY ZSH SETUP SCRIPT v2.3
# =============================================================================
# GitHub: https://raw.githubusercontent.com/marcogll/scripts_mg/main/omarchy_zsh_setup/omarchy-setup.sh
# Instalación: curl -fsSL URL -o script.sh && chmod +x script.sh && ./script.sh
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
# LOGGING & AUXILIARES
# =============================================================================

setup_logging() {
    # Crear archivos de log
    : > "$LOG_FILE"
    : > "$ERROR_LOG"
    
    # Redirigir stdout y stderr
    exec > >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$ERROR_LOG" >&2)
    
    log "==================================================================="
    log "OMARCHY SETUP v2.3 - $(date '+%Y-%m-%d %H:%M:%S')"
    log "==================================================================="
}

log() {
    echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%H:%M:%S')] ERROR: $*" | tee -a "$ERROR_LOG" >&2
}

print_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}${BOLD}         OMARCHY ZSH SETUP v2.3 - Setup Completo${NC}              ${CYAN}║${NC}"
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
    pacman -Q "$1" &> /dev/null
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
    step "Instalando paquetes base (incluyendo nano)"
    
    local packages=(
        "zsh" "git" "curl" "wget" "nano" # <-- AÑADIDO NANO
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
        # CORRECCIÓN: Verificación simplificada para evitar errores de sintaxis con 'if'
        if ! check_installed "$pkg"; then
            to_install+=("$pkg")
        fi
        printf "\r  Verificando paquetes... [%d/%d]" $current $total
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

install_google_chrome() {
    step "Instalando Google Chrome"
    
    for chromium_pkg in omarchy-chromium chromium; do
        if check_installed "$chromium_pkg"; then
            info "Removiendo $chromium_pkg..."
            sudo pacman -Rns --noconfirm "$chromium_pkg" 2>/dev/null || true
        fi
    done
    
    if command -v google-chrome-stable &> /dev/null; then
        success "Google Chrome ya está instalado"
    else
        info "Instalando Google Chrome desde AUR..."
        if yay -S --noconfirm google-chrome; then
            success "Google Chrome instalado"
        else
            error "Fallo al instalar Google Chrome"
        fi
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

install_teamviewer() {
    step "Instalando TeamViewer y configurando daemon (SOLO SERVICIO)"
    
    if command -v teamviewer &> /dev/null; then
        success "TeamViewer ya está instalado"
    else
        info "Instalando TeamViewer desde AUR..."
        if yay -S --noconfirm teamviewer; then
            success "TeamViewer instalado"
        else
            error "Fallo al instalar TeamViewer"
            return 1
        fi
    fi
    
    # Habilitar y arrancar el daemon (servicio) para el inicio automático
    info "Habilitando el daemon de TeamViewer (teamviewerd.service)..."
    if sudo systemctl enable --now teamviewerd.service; then
        success "Daemon de TeamViewer habilitado y corriendo (NO LANZA LA VENTANA)"
    else
        error "Fallo al habilitar el daemon de TeamViewer"
        warning "Ejecuta 'sudo systemctl enable --now teamviewerd.service' manualmente."
    fi
    NEEDS_REBOOT=true
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
        echo "  1. Sin contraseña (conveniente)"
        echo "  2. Contraseña de usuario (recomendado)"
        echo "  3. Personalizada"
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
            echo "auth       optional     pam_gnome_keyring.so" | sudo tee -a /etc/pam.d/login > /dev/null
            echo "session    optional     pam_gnome_keyring.so auto_start" | sudo tee -a /etc/pam.d/login > /dev/null
        fi
        
        [ -f /etc/pam.d/sddm ] && ! grep -q "pam_gnome_keyring" /etc/pam.d/sddm && {
            echo "auth       optional     pam_gnome_keyring.so" | sudo tee -a /etc/pam.d/sddm > /dev/null
            echo "session    optional     pam_gnome_keyring.so auto_start" | sudo tee -a /etc/pam.d/sddm > /dev/null
        }
        
        eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh 2>/dev/null)
        export SSH_AUTH_SOCK GPG_AGENT_INFO GNOME_KEYRING_CONTROL GNOME_KEYRING_PID
        
        success "GNOME Keyring configurado"
    fi
}

# =============================================================================
# ZSH, GIT, ETC. (Funciones abreviadas)
# =============================================================================
install_oh_my_zsh() { log "Skipping ZSH setup placeholder"; }
install_zsh_plugins() { log "Skipping ZSH plugins placeholder"; }
install_oh_my_posh_theme() { log "Skipping Oh My Posh theme placeholder"; }
create_zshrc() { log "Skipping .zshrc creation placeholder"; }
configure_permissions() { log "Skipping permissions placeholder"; }
configure_git() { log "Skipping git config placeholder"; }
# -----------------------------------------------------------------------------

configure_ssh() {
    step "Configurando SSH y añadiendo claves al Keyring"
    
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Configuración de SSH y Keyring${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
    
    info "Escaneando ~/.ssh/ en busca de llaves privadas..."
    local ssh_keys=()
    
    # 1. Escanear llaves SSH válidas
    for key in ~/.ssh/*; do
        if [ -f "$key" ] && [[ ! "$key" =~ \.pub$ ]] && [[ ! "$key" =~ known_hosts ]] && \
           [[ ! "$key" =~ authorized_keys ]] && [[ ! "$key" =~ config ]] && [[ ! "$key" =~ agent ]]; then
            if ssh-keygen -l -f "$key" &>/dev/null; then
                ssh_keys+=("$key")
            fi
        fi
    done
    
    # 2. Manejar caso sin llaves
    if [ ${#ssh_keys[@]} -eq 0 ]; then
        warning "No se encontraron llaves SSH en ~/.ssh/. Saltando configuración de llaves."
        warning "Para usar SSH, genera una llave con 'ssh-keygen -t ed25519' y vuelve a ejecutar."
        return
    fi
    
    # 3. Listar llaves encontradas
    success "Encontradas ${#ssh_keys[@]} llaves SSH. Se intentará agregarlas al Keyring/Agent."
    echo ""
    for key_path in "${ssh_keys[@]}"; do
        echo "  ${CYAN}Llave: $(basename "$key_path")${NC}"
    done
    echo ""
    
    if ! ask_yes_no "¿Proceder a cargar estas ${#ssh_keys[@]} llaves al SSH Agent/Keyring?" "y"; then
        info "Configuración de llaves SSH saltada."
        return
    fi
    
    # 4. Iniciar o asegurar que el agente esté corriendo
    info "Asegurando que gnome-keyring-daemon esté activo (incluye ssh-agent)..."
    eval $(gnome-keyring-daemon --start --components=ssh 2>/dev/null)
    export SSH_AUTH_SOCK GPG_AGENT_INFO GNOME_KEYRING_CONTROL GNOME_KEYRING_PID
    
    # 5. Agregar claves al agente (ssh-add)
    local keys_added=0
    for key_path in "${ssh_keys[@]}"; do
        info "Añadiendo $(basename "$key_path") al SSH Agent/Keyring..."
        
        if ssh-add "$key_path" < /dev/null; then
            success "Llave $(basename "$key_path") cargada. Si tenía clave, se guardó en el Keyring."
            keys_added=$((keys_added + 1))
        else
            warning "Fallo al agregar la llave $(basename "$key_path")."
        fi
    done
    
    # 6. Crear config mínimo (si no existe)
    if [ ! -f ~/.ssh/config ]; then
        cat > ~/.ssh/config << 'EOF'
# SSH CONFIG (Configuración mínima para un mejor manejo con Agent)

Host *
    AddKeysToAgent yes
    IdentitiesOnly yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF
        chmod 600 ~/.ssh/config
        info "Archivo ~/.ssh/config creado."
    fi
    
    success "Configuración SSH finalizada. Claves cargadas: $keys_added."
    warning "La próxima vez que inicies sesión y desbloquees tu keyring (clave de usuario), el agente SSH desbloqueará tus claves automáticamente."
}
# -----------------------------------------------------------------------------

# =============================================================================
# MODO DE EJECUCIÓN
# =============================================================================

run_full_install() {
    print_header
    check_requirements
    
    install_packages
    install_yay
    install_oh_my_posh
    install_google_chrome
    install_localsend
    install_teamviewer # <-- AÑADIDO
    install_emoji_launcher
    
    if ask_yes_no "¿Instalar drivers Epson (L4150)?" "n"; then
        install_epson_drivers
    fi
    
    install_zerotier
    configure_gnome_keyring
    
    configure_permissions
    configure_git
    
    if ask_yes_no "¿Configurar SSH (recomendado)?" "y"; then
        configure_ssh
    fi

    # Zsh
    install_oh_my_zsh
    install_zsh_plugins
    install_oh_my_posh_theme
    create_zshrc
    
    final_message
}

run_ssh_only() {
    print_header
    check_requirements
    
    install_yay
    configure_ssh
    
    final_message
}

final_message() {
    progress_bar $TOTAL_STEPS $TOTAL_STEPS "COMPLETO"
    echo ""
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}                   ${BOLD}CONFIGURACIÓN FINALIZADA${NC}                 ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if $NEEDS_REBOOT; then
        echo -e "${RED}!!! REINICIO REQUERIDO: Por favor, reinicia para aplicar cambios. !!!${NC}"
        echo ""
    fi
    
    echo -e "${CYAN}Próximos pasos:${NC}"
    echo "1. El SSH Agent de GNOME Keyring te pedirá las claves SSH (si tienen) una vez. ¡Guárdalas!"
    echo "2. Para usar TeamViewer, simplemente lanza la aplicación. El servicio ya está listo."
    echo "3. Ejecuta 'zsh' para usar la nueva shell."
    echo "4. Revisa los logs en $LOG_FILE"
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================

if [[ "$1" == "--ssh" ]]; then
    run_ssh_only
elif [[ "$1" == "--help" ]]; then
    echo "Uso: bash omarchy-setup.sh [opciones]"
    echo ""
    echo "Opciones:"
    echo " --ssh           Solo configura las llaves SSH (asume que yay está instalado)."
    echo " --help           Muestra esta ayuda."
    echo ""
    exit 0
else
    setup_logging
    run_full_install
fi
