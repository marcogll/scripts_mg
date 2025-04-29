#!/usr/bin/env bash
# auto_server_setup.sh — Marco G. & ChatGPT — 2025-04-28
# Prepara un home-server en Ubuntu 22.04/24.04 de forma (semi)automática.

set -euo pipefail

LOG(){ printf "\n\e[1;32m▶ %s\e[0m\n" "$*"; }

##########################
# 0. Comprobaciones previas
##########################
if [[ "$(id -u)" -ne 0 ]]; then
  echo "⚠️  Este script debe ejecutarse como root (sudo)."
  exit 1
fi

############  CONFIGURACIÓN INTERACTIVA  ############
echo -e "\n--- Configuración interactiva ---"

# 1) Usuario del sistema
DEFAULT_USER="${SUDO_USER:-$USER}"
read -rp "➤ Usuario a configurar [$DEFAULT_USER]: " TMP_USER
SERVER_USER="${TMP_USER:-$DEFAULT_USER}"

# 2) ¿Instalar Pi-hole?
read -rp "➤ ¿Instalar Pi-hole? [Y/n]: " TMP_PIHOLE
INSTALL_PIHOLE="$( [[ ${TMP_PIHOLE,,} =~ ^n ]] && echo no || echo yes )"

# 3) ¿Instalar CasaOS?
read -rp "➤ ¿Instalar CasaOS? [Y/n]: " TMP_CASAOS
INSTALL_CASAOS="$( [[ ${TMP_CASAOS,,} =~ ^n ]] && echo no || echo yes )"

# 4) ¿Reiniciar automáticamente al terminar?
read -rp "➤ ¿Reiniciar automáticamente al terminar? [Y/n]: " TMP_REBOOT
AUTO_REBOOT="$( [[ ${TMP_REBOOT,,} =~ ^n ]] && echo no || echo yes )"

echo -e "\nResumen:"
echo "  SERVER_USER   = $SERVER_USER"
echo "  INSTALL_PIHOLE= $INSTALL_PIHOLE"
echo "  INSTALL_CASAOS= $INSTALL_CASAOS"
echo "  AUTO_REBOOT   = $AUTO_REBOOT"
echo "-----------------------------------"
sleep 2
#####################################################

###################################
# 1. Base APT + actualizaciones
###################################
install_base() {
  LOG "Actualizando APT y herramientas básicas…"
  export DEBIAN_FRONTEND=noninteractive
  apt update && apt -y full-upgrade
  apt install -y git curl gnupg lsb-release nano \
                 ca-certificates software-properties-common \
                 apt-transport-https build-essential ufw
}

###################################
# 2. Zsh + Oh-My-Zsh + autosuggestions
###################################
install_shell() {
  LOG "Instalando Zsh y Oh-My-Zsh…"
  apt install -y zsh
  sudo -u "$SERVER_USER" mkdir -p /tmp
  sudo -u "$SERVER_USER" curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
        -o /tmp/install-ohmyzsh.sh
  sudo -u "$SERVER_USER" bash /tmp/install-ohmyzsh.sh --unattended
  chsh -s "$(command -v zsh)" "$SERVER_USER"

  LOG "Instalando plugin zsh-autosuggestions…"
  sudo -u "$SERVER_USER" git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
        "/home/$SERVER_USER/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
  sudo -u "$SERVER_USER" sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions)/' \
        "/home/$SERVER_USER/.zshrc"
}

###################################
# 3. Utilidades extra (fzf, btop)
###################################
install_utils() {
  LOG "Instalando fzf y btop…"
  apt install -y fzf btop
}

###################################
# 4. Certbot (Let’s Encrypt)
###################################
install_certbot() {
  LOG "Instalando Certbot (snap)…"
  snap install core --classic >/dev/null || true
  snap refresh core
  snap install --classic certbot
  ln -sf /snap/bin/certbot /usr/bin/certbot
}

###################################
# 5. Docker Engine + compose-plugin
###################################
install_docker() {
  LOG "Instalando Docker Engine…"
  apt remove -y docker docker.io containerd runc || true
  install -m0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
       gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  source /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
       > /etc/apt/sources.list.d/docker.list
  apt update
  apt install -y docker-ce docker-ce-cli containerd.io \
                 docker-buildx-plugin docker-compose-plugin
  usermod -aG docker "$SERVER_USER"
}

###################################
# 6. ZeroTier One
###################################
install_zerotier() {
  LOG "Instalando ZeroTier…"
  curl -s https://install.zerotier.com | bash
}

###################################
# 7. Portainer (contenedor Docker)
###################################
install_portainer() {
  LOG "Desplegando Portainer CE…"
  docker volume create portainer_data
  docker run -d --name portainer \
    -p 8000:8000 -p 9443:9443 \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest
}

###################################
# 8. CasaOS (opcional)
###################################
install_casaos() {
  [[ "$INSTALL_CASAOS" == "no" ]] && return
  LOG "Instalando CasaOS…"
  curl -fsSL https://get.casaos.io | bash
}

###################################
# 9. Pi-hole (opcional, nativo)
###################################
install_pihole() {
  [[ "$INSTALL_PIHOLE" == "no" ]] && return
  LOG "Instalando Pi-hole… (modo unattended)"
  export PIHOLE_SKIP_OS_CHECK=true
  curl -sSL https://install.pi-hole.net | bash -s -- --unattended
}

###################################
# 10. Plex Media Server (nativo)
###################################
install_plex() {
  LOG "Instalando Plex Media Server…"
  curl -fsSL https://downloads.plex.tv/plex-keys/PlexSign.key | \
       gpg --dearmor -o /etc/apt/trusted.gpg.d/plex.gpg
  echo "deb [signed-by=/etc/apt/trusted.gpg.d/plex.gpg] https://downloads.plex.tv/repo/deb/ public main" \
       > /etc/apt/sources.list.d/plexmediaserver.list
  apt update
  apt install -y plexmediaserver
}

############################
# Ejecución en cascada
############################
main() {
  install_base
  install_shell
  install_utils
  install_certbot
  install_docker
  install_zerotier
  install_portainer
  install_casaos
  install_pihole
  install_plex

  LOG "🎉 Instalación completa."
  LOG "Accesos:\n  • Portainer → https://<IP>:9443\n  • CasaOS → http://<IP>\n  • Plex → http://<IP>:32400/web\n  • Pi-hole → http://<IP>/admin"

  if [[ "$AUTO_REBOOT" == "yes" ]]; then
    LOG "Reiniciando en 10 s…  (Ctrl-C para abortar)"
    sleep 10 && reboot
  else
    read -rp $'\n¿Deseas reiniciar ahora? [y/N]: ' REPLY
    if [[ ${REPLY,,} == "y" ]]; then
      LOG "Reiniciando…"
      reboot
    else
      LOG "No se reinició. Hazlo manualmente cuando quieras."
    fi
  fi
}

main "$@"
