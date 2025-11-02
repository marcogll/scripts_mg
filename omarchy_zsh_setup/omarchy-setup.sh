#!/usr/bin/env bash
# =============================================================================
#     Omarchy Setup Script v2.8.1 (Omarchy-MG Fusión)
#     Autor: Marco G. / 2025
#     Descripción:
#       Versión unificada que combina la estética Catppuccin con la robustez
#       y características de versiones anteriores.
#       Omite la instalación automática de Nerd Fonts a petición del usuario.
# =============================================================================

# Estricto: errores no manejados, variables no definidas y pipes fallidos causan salida
set -euo pipefail

# =============================================================================
# COLORES Y CONFIGURACIÓN GLOBAL (Catppuccin Latte Palette)
# =============================================================================
# Latte es el tema claro de Catppuccin - colores más brillantes y vibrantes
FLAMINGO="\e[38;5;174m"  # #dd7878 - rosado suave
MAUVE="\e[38;5;135m"     # #8839ef - morado vibrante
PEACH="\e[38;5;208m"    # #fe640b - naranja/durazno brillante
GREEN="\e[38;5;70m"      # #40a02b - verde medio
TEAL="\e[38;5;37m"      # #179299 - teal medio
YELLOW="\e[38;5;214m"   # #df8e1d - amarillo dorado
RED="\e[38;5;196m"      # #d20f39 - rojo vibrante
BLUE="\e[38;5;27m"      # #1e66f5 - azul brillante
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
    echo "OMARCHY SETUP v2.8.1 - MG Setup Script - $(date '+%Y-%m-%d %H:%M:%S')"
    echo "==================================================================="
}

log()       { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2; }

print_header() {
    clear
    echo -e "${MAUVE}╔════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${MAUVE}║${RESET}         ${PEACH}OMARCHY SETUP v2.8.1 - MG Setup Script${RESET}             ${MAUVE}║${RESET}"
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

step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo -e "\n${YELLOW}→ [${CURRENT_STEP}/${TOTAL_STEPS}] $1${RESET}"
    progress_bar $CURRENT_STEP $TOTAL_STEPS "$1"
    sleep 0.3
}

success() {
    echo -e "\n${GREEN}✓ $1${RESET}"
    log "SUCCESS: $1"
}

warning() {
    echo -e "\n${PEACH}⚠ $1${RESET}"
    log "WARNING: $1"
}

error() {
    echo -e "\n${RED}✗ $1${RESET}"
    log_error "$1"
}

info() {
    echo -e "${TEAL}ℹ $1${RESET}"
    log "INFO: $1"
}

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

check_installed() {
    pacman -Q "$1" &> /dev/null
}

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
        teamviewer audacity inkscape yt-dlp ffmpeg playerctl
        brightnessctl pamixer lsof net-tools gnome-keyring libsecret seahorse
        fastfetch htop btop tree p7zip unrar
    )
    
    info "Actualizando base de datos de paquetes..."
    sudo pacman -Sy --noconfirm || warning "Error al actualizar base de datos, continuando..."
    
    local to_install=()
    local failed=()
    
    # Identificar paquetes que faltan
    for pkg in "${packages[@]}"; do
        if ! check_installed "$pkg"; then
            to_install+=("$pkg")
        fi
    done
    
    # Instalar paquetes faltantes
    if [ ${#to_install[@]} -gt 0 ]; then
        info "Instalando ${#to_install[@]} paquetes nuevos..."
        # Instalar paquetes de forma individual para mejor manejo de errores
        for pkg in "${to_install[@]}"; do
            if sudo pacman -S --noconfirm --needed "$pkg" 2>/dev/null; then
                info "✓ $pkg instalado correctamente"
            else
                warning "✗ No se pudo instalar $pkg, continuando..."
                failed+=("$pkg")
            fi
        done
        
        if [ ${#failed[@]} -gt 0 ]; then
            warning "Los siguientes paquetes no se pudieron instalar: ${failed[*]}"
        fi
    else
        info "Todos los paquetes base ya están instalados."
    fi
    
    # Instalar oh-my-posh desde AUR si no está instalado
    if ! command -v oh-my-posh &>/dev/null; then
        info "Instalando oh-my-posh desde AUR..."
        if command -v yay &>/dev/null; then
            yay -S --noconfirm oh-my-posh-bin 2>/dev/null || warning "No se pudo instalar oh-my-posh desde AUR"
        else
            warning "yay no está disponible, oh-my-posh se instalará después de instalar yay"
        fi
    fi
    
    # Instalar speedtest-cli si no está disponible
    if ! command -v speedtest &>/dev/null; then
        info "Instalando speedtest-cli..."
        sudo pip install --break-system-packages speedtest-cli 2>/dev/null || warning "No se pudo instalar speedtest-cli"
    fi
    
    success "Paquetes base instalados."
}

install_yay() {
    step "Instalando 'yay' (AUR helper)"
    
    # Verificar si yay ya está instalado
    if command -v yay &> /dev/null; then
        success "yay ya está instalado."
        # Intentar instalar oh-my-posh si aún no está instalado
        if ! command -v oh-my-posh &>/dev/null; then
            info "Instalando oh-my-posh desde AUR..."
            yay -S --noconfirm oh-my-posh-bin 2>/dev/null || warning "No se pudo instalar oh-my-posh desde AUR"
        fi
        return
    fi
    
    # Compilar yay desde AUR
    info "Clonando y compilando yay desde AUR..."
    (
        cd /tmp
        rm -rf yay
        if git clone https://aur.archlinux.org/yay.git --quiet 2>/dev/null; then
            cd yay
            makepkg -si --noconfirm --nocheck 2>/dev/null || {
                cd /
                rm -rf /tmp/yay
                return 1
            }
        else
            return 1
        fi
    ) || {
        warning "No se pudo instalar yay desde AUR. Continuando sin yay..."
        return 0
    }
    
    # Verificar instalación y instalar oh-my-posh si es necesario
    if command -v yay &> /dev/null; then
        success "yay instalado correctamente."
        # Instalar oh-my-posh después de instalar yay
        if ! command -v oh-my-posh &>/dev/null; then
            info "Instalando oh-my-posh desde AUR..."
            yay -S --noconfirm oh-my-posh-bin 2>/dev/null || warning "No se pudo instalar oh-my-posh desde AUR"
        fi
    else
        warning "yay no se pudo verificar después de la instalación. Continuando..."
    fi
}

setup_docker() {
    step "Configurando Docker y permisos de usuario"
    if check_installed docker; then
        sudo systemctl enable --now docker.service 2>/dev/null || warning "No se pudo iniciar docker.service"
        sudo usermod -aG docker "$USER" 2>/dev/null || warning "No se pudo añadir usuario al grupo docker"
        success "Docker configurado. Recuerda cerrar y volver a iniciar sesión."
    else
        warning "Docker no está instalado, omitiendo configuración."
    fi
}

install_ohmyzsh() {
    step "Instalando Oh My Zsh y plugins"
    
    # Instalar Oh My Zsh si no está instalado
    if [ -d "$HOME/.oh-my-zsh" ]; then
        info "Oh My Zsh ya está instalado."
    else
        info "Instalando Oh My Zsh..."
        if RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 2>/dev/null; then
            info "Oh My Zsh instalado correctamente."
        else
            warning "No se pudo instalar Oh My Zsh desde el repositorio oficial, continuando..."
        fi
    fi
    
    # Configurar directorio de plugins personalizados
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    mkdir -p "$ZSH_CUSTOM/plugins" 2>/dev/null || {
        warning "No se pudo crear directorio de plugins, continuando..."
        return 0
    }
    
    # Instalar plugin de autosugerencias
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null || warning "No se pudo instalar zsh-autosuggestions"
    fi
    
    # Instalar plugin de resaltado de sintaxis
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null || warning "No se pudo instalar zsh-syntax-highlighting"
    fi
    
    success "Oh My Zsh y plugins listos."
}

install_zshrc_and_posh_theme() {
    step "Aplicando configuración .zshrc y tema Catppuccin"
    
    local ZSHRC_URL="https://raw.githubusercontent.com/marcogll/scripts_mg/main/omarchy_zsh_setup/.zshrc"
    local DEST="$HOME/.zshrc"
    
    # Crear backup del .zshrc existente
    if [ -f "$DEST" ]; then
        if cp "$DEST" "${DEST}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null; then
            info "Backup del .zshrc existente creado."
        else
            warning "No se pudo crear backup del .zshrc, continuando..."
        fi
    fi
    
    # Descargar nuevo .zshrc desde GitHub
    if curl -fsSL "$ZSHRC_URL" -o "$DEST" 2>/dev/null; then
        info "Nuevo .zshrc instalado desde GitHub."
    else
        warning "Fallo al descargar .zshrc desde GitHub. Puedes configurarlo manualmente más tarde."
    fi
    
    # Crear directorio para temas de Oh My Posh
    mkdir -p ~/.poshthemes 2>/dev/null || {
        warning "No se pudo crear directorio ~/.poshthemes"
    }
    
    # Descargar tema Catppuccin Frappe
    if curl -fsSL https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/catppuccin_frappe.omp.json -o ~/.poshthemes/catppuccin.omp.json 2>/dev/null; then
        info "Tema Catppuccin Frappe descargado."
    else
        warning "No se pudo descargar el tema Catppuccin Frappe, continuando..."
    fi
    
    # Configurar zsh como shell por defecto (solo verificación, sin cambiar interactivamente)
    if command -v zsh &>/dev/null; then
        local zsh_path=$(which zsh)
        if [ -n "$zsh_path" ]; then
            # Verificar si el shell actual ya es zsh
            current_shell=$(getent passwd "$USER" | cut -d: -f7)
            if [ "$current_shell" = "$zsh_path" ]; then
                info "El shell por defecto ya es zsh."
            else
                # Asegurarse de que zsh está en /etc/shells
                if ! grep -Fxq "$zsh_path" /etc/shells 2>/dev/null; then
                    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null 2>&1 || true
                fi
                # Informar al usuario sobre cómo cambiar el shell manualmente
                info "Para cambiar el shell a zsh, ejecuta manualmente: chsh -s $zsh_path"
            fi
        fi
        success "Zsh listo para usar (cierra y abre la terminal para cambiar al shell)."
    else
        warning "zsh no está disponible, omitiendo configuración de shell."
    fi
}

setup_teamviewer() {
    step "Configurando TeamViewer"
    if check_installed teamviewer; then
        sudo systemctl enable --now teamviewerd.service 2>/dev/null || warning "No se pudo iniciar teamviewerd.service"
        success "Servicio de TeamViewer habilitado y activo."
        NEEDS_REBOOT=true
    else
        warning "TeamViewer no está instalado, omitiendo configuración."
    fi
}

install_zerotier() {
    step "Configurando ZeroTier One"
    if ! command -v zerotier-cli &> /dev/null; then
        if command -v yay &>/dev/null; then
            info "Instalando ZeroTier One desde AUR..."
            yay -S --noconfirm zerotier-one 2>/dev/null || {
                warning "No se pudo instalar ZeroTier One desde AUR"
                return 0
            }
        else
            warning "yay no está disponible, no se puede instalar ZeroTier One"
            return 0
        fi
    fi
    
    if command -v zerotier-cli &>/dev/null; then
        sudo systemctl enable --now zerotier-one.service 2>/dev/null || warning "No se pudo iniciar zerotier-one.service"
        NEEDS_REBOOT=true
        if ask_yes_no "¿Deseas unirte a una red ZeroTier ahora?" "y"; then
            read -p "$(echo -e ${YELLOW}Ingresa el Network ID: ${RESET})" ZEROTIER_NETWORK
            if [ -n "$ZEROTIER_NETWORK" ]; then
                info "Enviando solicitud para unirse a la red..."
                sudo zerotier-cli join "$ZEROTIER_NETWORK" 2>/dev/null || warning "No se pudo unir a la red ZeroTier"
                warning "Recuerda autorizar este equipo en my.zerotier.com"
            fi
        fi
        success "ZeroTier configurado."
    else
        warning "ZeroTier One no está disponible, omitiendo configuración."
    fi
}

configure_gnome_keyring() {
    step "Configurando GNOME Keyring (almacén de contraseñas)"
    
    if ask_yes_no "¿Configurar GNOME Keyring para guardar claves de Git/SSH?" "y"; then
        info "Configurando PAM para auto-desbloqueo..."
        
        # Configurar PAM para auto-desbloqueo del Keyring
        if ! grep -q "pam_gnome_keyring" /etc/pam.d/login 2>/dev/null; then
            echo "auth       optional     pam_gnome_keyring.so" | sudo tee -a /etc/pam.d/login > /dev/null
            echo "session    optional     pam_gnome_keyring.so auto_start" | sudo tee -a /etc/pam.d/login > /dev/null
        fi
        
        # Iniciar gnome-keyring-daemon
        eval "$(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh 2>/dev/null)"
        export SSH_AUTH_SOCK
        
        success "GNOME Keyring configurado."
    fi
}

configure_ssh() {
    step "Configurando claves SSH con el agente"
    
    if ask_yes_no "¿Buscar y añadir claves SSH existentes al agente?" "y"; then
        # Asegurar que el directorio .ssh existe con permisos correctos
        mkdir -p ~/.ssh && chmod 700 ~/.ssh
        
        # Buscar claves SSH válidas
        local ssh_keys=()
        for key in ~/.ssh/*; do
            if [ -f "$key" ] && ! [[ "$key" =~ \.pub$|known_hosts|authorized_keys|config|agent ]]; then
                ssh-keygen -l -f "$key" &>/dev/null && ssh_keys+=("$key")
            fi
        done
        
        # Verificar si se encontraron claves
        if [ ${#ssh_keys[@]} -eq 0 ]; then
            warning "No se encontraron claves SSH. Genera una con 'ssh-keygen'."
            return
        fi
        
        # Iniciar gnome-keyring-daemon para SSH
        info "Se encontraron ${#ssh_keys[@]} claves. Intentando añadirlas..."
        eval "$(gnome-keyring-daemon --start --components=ssh 2>/dev/null)"
        export SSH_AUTH_SOCK
        
        # Añadir claves al agente
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
    echo -e "  1. ${YELLOW}CIERRA Y VUELVE A ABRIR LA TERMINAL${RESET} o reinicia tu sesión para usar Zsh."
    echo -e "  2. ${PEACH}NOTA:${RESET} La instalación de fuentes fue omitida. Asegúrate de tener una 'Nerd Font'"
    echo "     instalada manualmente para que los iconos del prompt se vean correctamente."
    echo "  3. La primera vez que uses una clave SSH, se te pedirá la contraseña para guardarla en el Keyring."
    echo "  4. Comandos para verificar: ${BLUE}docker ps${RESET}, ${BLUE}teamviewer info${RESET}, ${BLUE}speedtest${RESET}, ${BLUE}zsh${RESET}."
    echo -e "\n${MAUVE}🚀 ¡Listo para usar Omarchy con la paleta Catppuccin!${RESET}\n"
}

# =============================================================================
# EJECUCIÓN PRINCIPAL
# =============================================================================
main() {
    # Inicializar logging y mostrar cabecera
    setup_logging
    print_header

    # Verificaciones iniciales
    check_requirements
    
    # Instalación de paquetes y herramientas base
    install_packages
    install_yay
    
    # Configuración de servicios base
    setup_docker
    
    # Configuración de Zsh y shell
    install_ohmyzsh
    install_zshrc_and_posh_theme
    
    # Configuración de servicios opcionales
    setup_teamviewer
    install_zerotier
    
    # Configuración de seguridad y claves
    configure_gnome_keyring
    configure_ssh

    # Mensaje final
    final_message
}

# Ejecutar script principal
main "$@"
