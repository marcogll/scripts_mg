#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# =====================
# Configuración inicial
# =====================
SERVER_USER="your_username"    # <- Reemplaza con tu nombre de usuario en el servidor
INSTALL_PIHOLE="no"            # <- "yes" para instalar Pi-hole, "no" para omitir
INSTALL_CASAOS="no"            # <- "yes" para instalar CasaOS, "no" para omitir
AUTO_REBOOT="no"               # <- "yes" para reiniciar automáticamente, "no" para preguntar

# Logging function
LOG() {
    echo -e "[`date +'%Y-%m-%d %H:%M:%S'`] $@"
}

# Comprueba que el script se esté ejecutando como root
if [ "$(id -u)" -ne 0 ]; then
    echo "Por favor, ejecuta este script como root o con sudo."
    exit 1
fi

if ! id "$SERVER_USER" >/dev/null 2>&1; then
    echo "Usuario $SERVER_USER no encontrado. Por favor verifica la configuración de SERVER_USER."
    exit 1
fi

# Función para instalar paquetes base
install_base_packages() {
    LOG "Instalando paquetes base..."
    export DEBIAN_FRONTEND=noninteractive
    apt update && apt upgrade -y
    apt install -y build-essential curl wget git ufw snapd lsb-release apt-transport-https ca-certificates gnupg
}

# Función para instalar Zsh, Oh-My-Zsh, y zsh-autosuggestions
install_zsh_ohmyzsh() {
    LOG "Instalando Zsh y Oh-My-Zsh..."
    apt install -y zsh
    
    # Instalar Oh-My-Zsh para el usuario especificado
    sudo -H -u "$SERVER_USER" bash -c "mkdir -p /tmp && curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o /tmp/install-ohmyzsh.sh"
    sudo -H -u "$SERVER_USER" bash -c "bash /tmp/install-ohmyzsh.sh --unattended"
    
    # Cambiar el shell predeterminado del usuario a zsh
    chsh -s "$(which zsh)" "$SERVER_USER"
    
    # Instalar plugin zsh-autosuggestions
    LOG "Instalando complemento zsh-autosuggestions..."
    sudo -H -u "$SERVER_USER" git clone https://github.com/zsh-users/zsh-autosuggestions "/home/$SERVER_USER/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    
    # Habilitar el plugin zsh-autosuggestions en el .zshrc del usuario
    sudo -H -u "$SERVER_USER" sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions)/' "/home/$SERVER_USER/.zshrc"
}

# Función para instalar fzf y btop
install_fzf_btop() {
    LOG "Instalando fzf y btop..."
    apt install -y fzf btop
}

# Función para instalar Certbot mediante snap
install_certbot() {
    LOG "Instalando Certbot (snap)..."
    # Asegurarse de que snap core esté instalado y actualizado
    snap install core || true
    snap refresh core
    # Instalar Certbot
    snap install --classic certbot
    ln -s /snap/certbot/current/bin/certbot /usr/bin/certbot || true
}

# Función para instalar Docker Engine y docker-compose plugin
install_docker() {
    LOG "Instalando Docker Engine y Docker Compose Plugin..."
    # Desinstalar versiones antiguas de Docker si existen
    apt remove -y docker docker.io containerd runc || true
    
    # Instalar paquetes de soporte
    apt install -y ca-certificates curl gnupg
    
    # Agregar clave GPG oficial de Docker
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Agregar repositorio de Docker
    source /etc/os-release
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $VERSION_CODENAME stable" > /etc/apt/sources.list.d/docker.list
    
    # Instalar Docker Engine, CLI, Containerd, Buildx y Compose
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Agregar el usuario al grupo docker para evitar usar sudo con Docker
    usermod -aG docker "$SERVER_USER" || true
    LOG "Docker Engine y Docker Compose instalados."
}

# Función para instalar ZeroTier One
install_zerotier() {
    LOG "Instalando ZeroTier One..."
    curl -fsSL https://install.zerotier.com | bash
}

# Función para desplegar Portainer en un contenedor Docker
install_portainer() {
    LOG "Desplegando Portainer (contenedor Docker)..."
    docker volume create portainer_data || true
    docker run -d \
        -p 8000:8000 -p 9000:9000 -p 9443:9443 \
        --name portainer --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:latest
}

# Función opcional para instalar CasaOS
install_casaos() {
    if [ "$INSTALL_CASAOS" = "yes" ]; then
        LOG "Instalando CasaOS..."
        curl -fsSL https://get.casaos.io | bash
    fi
}

# Función opcional para instalar Pi-hole
install_pihole() {
    if [ "$INSTALL_PIHOLE" = "yes" ]; then
        LOG "Instalando Pi-hole (puede tardar unos minutos)..."
        curl -fsSL https://install.pi-hole.net | bash -s -- --unattended
    fi
}

# Función para instalar Plex Media Server
install_plex() {
    LOG "Instalando Plex Media Server..."
    # Agregar clave y repositorio de Plex
    curl -fsSL https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/plex.gpg
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/plex.gpg] https://downloads.plex.tv/repo/deb/ public main" > /etc/apt/sources.list.d/plexmediaserver.list
    apt update
    apt install -y plexmediaserver
}

# Función principal para ejecutar todas las instalaciones
main_setup() {
    install_base_packages
    install_zsh_ohmyzsh
    install_fzf_btop
    install_certbot
    install_docker
    install_zerotier
    install_portainer
    install_casaos
    install_pihole
    install_plex
    
    LOG "Configuración finalizada."
    if [ "$AUTO_REBOOT" = "yes" ]; then
        LOG "Reiniciando el sistema en 5 segundos..."
        sleep 5
        reboot
    else
        echo -n "¿Desea reiniciar el servidor ahora? (s/N): "
        read -r CONFIRM
        if [[ "$CONFIRM" =~ ^([sS][iI]?|[yY])$ ]]; then
            LOG "Reiniciando el sistema..."
            sleep 2
            reboot
        else
            LOG "Instalación completada. Reinicia manualmente para aplicar los cambios."
        fi
    fi
}

# Ejecutar el proceso principal
main_setup
