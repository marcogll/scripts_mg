#!/usr/bin/env bash
# =============================================================================
#     Omarchy Setup Script v2.8.3 (Omarchy-MG Fusión)
#     Autor: Marco G. / 2025
#     Descripción:
#       Versión unificada que combina la estética Catppuccin con la robustez
#       y características de versiones anteriores.
#       Omite la instalación automática de Nerd Fonts a petición del usuario.
# =============================================================================

set -euo pipefail

# =============================================================================
# COLORES Y CONFIGURACIÓN GLOBAL (Catppuccin Palette)
# =============================================================================
FLAMINGO="\e[38;5;245m"
MAUVE="\e[38;5;140m"
PEACH="\e[38;5;215m"
GREEN="\e[38;5;121m"
TEAL="\e[38;5;80m"
YELLOW="\e[38;5;229m"
RED="\e[38;5;203m"
BLUE="\e[38;5;75m"
RESET="\e[0m"

TOTAL_STEPS=11 # Se redujo el número de pasos
CURRENT_STEP=0
NEEDS_REBOOT=false
LOG_FILE="$HOME/omarchy-setup.log"
ERROR_LOG="$HOME/omarchy-errors.log"

# =============================================================================
# LOGGING, UI Y FUNCIONES AUXILIARES
# =============================================================================
setup_logging() {
    : > "$LOG_FILE"
    : > "$ERROR_LOG"
    exec > >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$ERROR_LOG" >&2)
    echo "==================================================================="
    echo "OMARCHY SETUP v2.8.3 - $(date '+%Y-%m-%d %H:%M:%S')"
    echo "==================================================================="
}

log()     { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2; }

print_header() {
    clear
    echo -e "${MAUVE}╔════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${MAUVE}║${RESET}         ${PEACH}OMARCHY SETUP v2.8.3 - Edición Fusión${RESET}             ${MAUVE}║${RESET}"
    echo -e "${MAUVE}╚════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${TEAL}Logs:${RESET} $LOG_FILE"
    echo -e "${RED}Errores:${RESET} $ERROR_LOG"
    echo ""
}

progress_bar() {
    local step=$1
    local total=$2
    local text=$3
    local percent=$((step * 100 / total))
    local completed=$((step * 40 / total))
    local remaining=$((40 - completed))
    printf "\r${BLUE}["
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "]${RESET} ${percent}%% - ${text}"
}

step()    { CURRENT_STEP=$((CURRENT_STEP + 1)); echo -e "\n${YELLOW}→ [${CURRENT_STEP}/${TOTAL_STEPS}] $1${RESET}"; progress_bar $CURRENT_STEP $TOTAL_STEPS "$1"; sleep 0.3; }
success() { echo -e "\n${GREEN}✓ $1${RESET}"; log "SUCCESS: $1"; }
warning() { echo -e "\n${PEACH}⚠ $1${RESET}"; log "WARNING: $1"; }
error()   { echo -e "\n${RED}✗ $1${RESET}"; log_error "$1"; }
info()    { echo -e "${TEAL}ℹ $1${RESET}"; log "INFO: $1"; }

ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    [[ "$default" == "y" ]] && prompt+=" [Y/n]: " || prompt+=" [y/N]: "
    while true; do
        read -p "$(echo -e ${YELLOW}$prompt${RESET})" response
        response=${response:-$default}
        case $response in
            [Yy]*) log "USER: $prompt -> YES"; return 0;;
            [Nn]*) log "USER: $prompt -> NO"; return 1;;
            *) echo "Por favor responde sí (y) o no (n).";;
        esac
    done
}

check_installed() { pacman -Q "$1" &> /dev/null; }

# =============================================================================
# FUNCIONES PRINCIPALES DE INSTALACIÓN
# =============================================================================
check_requirements() {
    step "Verificando requerimientos del sistema"
    if [ "$EUID" -eq 0 ]; then error "No ejecutes este script como root."; exit 1; fi
    if ! command -v pacman &> /dev/null; then error "Este script es solo para Arch Linux."; exit 1; fi
    if ! ping -c 1 archlinux.org &>/dev/null; then error "Sin conexión a Internet. Abortando."; exit 1; fi
    success "Requerimientos verificados."
}

install_packages() {
    step "Instalando paquetes base y utilidades"
    local packages=(
        git curl wget unzip tar base-devel zsh zsh-completions eza bat zoxide nano
        python-pip python-virtualenv nodejs npm go docker docker-compose
        teamviewer audacity inkscape oh-my-posh yt-dlp ffmpeg playerctl
        brightnessctl pamixer lsof net-tools gnome-keyring libsecret seahorse
        fastfetch htop btop tree p7zip unrar
    )
    info "Actualizando base de datos de paquetes..."
    sudo pacman -Sy --noconfirm
    local to_install=()
    for pkg in "${packages[@]}"; do
        ! check_installed "$pkg" && to_install+=("$pkg")
    done
    if [ ${#to_install[@]} -gt 0 ]; then
        info "Instalando ${#to_install[@]} paquetes nuevos..."
        sudo pacman -S --noconfirm --needed "${to_install[@]}"
    fi
    if ! command -v speedtest &>/dev/null; then
        sudo pip install --break-system-packages speedtest-cli || true
    fi
    success "Paquetes base instalados."
}

install_yay() {
    step "Instalando 'yay' (AUR helper)"
    if command -v yay &> /dev/null; then success "yay ya está instalado."; return; fi
    info "Clonando y compilando yay desde AUR..."
    (
        cd /tmp
        rm -rf yay
        git clone https://aur.archlinux.org/yay.git --quiet
        cd yay
        makepkg -si --noconfirm --nocheck
    )
    if command -v yay &> /dev/null; then success "yay instalado correctamente."; else error "Fallo al instalar yay."; exit 1; fi
}

setup_docker() {
    step "Configurando Docker y permisos de usuario"
    sudo systemctl enable --now docker.service
    sudo usermod -aG docker "$USER"
    success "Docker configurado. Recuerda cerrar y volver a iniciar sesión."
}

install_ohmyzsh() {
    step "Instalando Oh My Zsh y plugins"
    if [ -d "$HOME/.oh-my-zsh" ]; then info "Oh My Zsh ya está instalado."; else
        RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    mkdir -p "$ZSH_CUSTOM/plugins"
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null || true
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null || true
    success "Oh My Zsh y plugins listos."
}

install_zshrc_and_posh_theme() {
    step "Aplicando configuración .zshrc y tema Catppuccin"
    local ZSHRC_URL="https://raw.githubusercontent.com/marcogll/scripts_mg/main/omarchy_zsh_setup/.zshrc"
    local DEST="$HOME/.zshrc"
    if [ -f "$DEST" ]; then
        cp "$DEST" "${DEST}.backup.$(date +%Y%m%d_%H%M%S)"
        info "Backup del .zshrc existente creado."
    fi
    if curl -fsSL "$ZSHRC_URL" -o "$DEST"; then
        info "Nuevo .zshrc instalado desde GitHub."
    else
        error "Fallo al descargar .zshrc. Abortando."
        exit 1
    fi
    mkdir -p ~/.poshthemes
    wget https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/catppuccin_frappe.omp.json -O ~/.poshthemes/catppuccin.omp.json -q
    info "Tema Catppuccin Frappe descargado."
    chsh -s "$(which zsh)" "$USER" || true
    success "Zsh configurado como shell por defecto."
}

setup_teamviewer() {
    step "Configurando TeamViewer"
    sudo systemctl enable --now teamviewerd.service
    success "Servicio de TeamViewer habilitado y activo."
    NEEDS_REBOOT=true
}

install_zerotier() {
    step "Configurando ZeroTier One"
    if ! command -v zerotier-cli &> /dev/null; then
      yay -S --noconfirm zerotier-one
    fi
    sudo systemctl enable --now zerotier-one.service
    NEEDS_REBOOT=true
    if ask_yes_no "¿Deseas unirte a una red ZeroTier ahora?" "y"; then
        read -p "$(echo -e ${YELLOW}Ingresa el Network ID: ${RESET})" ZEROTIER_NETWORK
        if [ -n "$ZEROTIER_NETWORK" ]; then
            info "Enviando solicitud para unirse a la red..."
            sudo zerotier-cli join "$ZEROTIER_NETWORK"
            warning "Recuerda autorizar este equipo en my.zerotier.com"
        fi
    fi
    success "ZeroTier configurado."
}

configure_gnome_keyring() {
    step "Configurando GNOME Keyring (almacén de contraseñas)"
    if ask_yes_no "¿Configurar GNOME Keyring para guardar claves de Git/SSH?" "y"; then
        info "Configurando PAM para auto-desbloqueo..."
        if ! grep -q "pam_gnome_keyring" /etc/pam.d/login 2>/dev/null; then
            echo "auth       optional     pam_gnome_keyring.so" | sudo tee -a /etc/pam.d/login > /dev/null
            echo "session    optional     pam_gnome_keyring.so auto_start" | sudo tee -a /etc/pam.d/login > /dev/null
        fi
        eval "$(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh 2>/dev/null)"
        export SSH_AUTH_SOCK
        success "GNOME Keyring configurado."
    fi
}

configure_ssh() {
    step "Configurando claves SSH con el agente"
    if ask_yes_no "¿Buscar y añadir claves SSH existentes al agente?" "y"; then
        mkdir -p ~/.ssh && chmod 700 ~/.ssh
        local ssh_keys=()
        for key in ~/.ssh/*; do
            if [ -f "$key" ] && ! [[ "$key" =~ \.pub$|known_hosts|authorized_keys|config|agent ]]; then
                ssh-keygen -l -f "$key" &>/dev/null && ssh_keys+=("$key")
            fi
        done
        if [ ${#ssh_keys[@]} -eq 0 ]; then
            warning "No se encontraron claves SSH. Genera una con 'ssh-keygen'."
            return
        fi
        info "Se encontraron ${#ssh_keys[@]} claves. Intentando añadirlas..."
        eval "$(gnome-keyring-daemon --start --components=ssh 2>/dev/null)"
        export SSH_AUTH_SOCK
        for key_path in "${ssh_keys[@]}"; do
            ssh-add "$key_path" < /dev/null && info "Clave '$(basename "$key_path")' añadida."
        done
        success "Claves SSH añadidas al agente."
    fi
}

final_message() {
    progress_bar $TOTAL_STEPS $TOTAL_STEPS "COMPLETADO"
    echo -e "\n\n${GREEN}╔════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}║${RESET}                   ${PEACH}CONFIGURACIÓN FINALIZADA${RESET}                 ${GREEN}║${RESET}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${RESET}\n"

    if $NEEDS_REBOOT; then
        echo -e "${RED}⚠ REINICIO REQUERIDO para aplicar todos los cambios (TeamViewer, ZeroTier, etc.).${RESET}\n"
    fi

    echo -e "${TEAL}Próximos pasos:${RESET}"
    echo "  1. ${YELLOW}CIERRA Y VUELVE A ABRIR LA TERMINAL${RESET} o reinicia tu sesión para usar Zsh."
    echo "  2. ${PEACH}NOTA:${RESET} La instalación de fuentes fue omitida. Asegúrate de tener una 'Nerd Font'"
    echo "     instalada manualmente para que los iconos del prompt se vean correctamente."
    echo "  3. La primera vez que uses una clave SSH, se te pedirá la contraseña para guardarla en el Keyring."
    echo "  4. Comandos para verificar: 'docker ps', 'teamviewer info', 'speedtest', 'zsh'."
    echo -e "\n${MAUVE}🚀 ¡Listo para usar Omarchy con la paleta Catppuccin!${RESET}"
}

# =============================================================================
# EJECUCIÓN PRINCIPAL
# =============================================================================
main() {
    setup_logging
    print_header

    check_requirements
    install_packages
    install_yay
    setup_docker
    install_ohmyzsh
    install_zshrc_and_posh_theme
    setup_teamviewer
    
    # Módulos opcionales
    install_zerotier
    configure_gnome_keyring
    configure_ssh

    final_message
}

main "$@"
