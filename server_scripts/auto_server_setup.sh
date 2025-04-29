cat > auto_server_setup.sh <<'SCRIPT'
#!/usr/bin/env bash
# auto_server_setup.sh — Marco G. & ChatGPT — 2025-04-28
set -euo pipefail
LOG(){ printf "\n\e[1;32m▶ %s\e[0m\n" "$*"; }

# -------- Ajusta aquí ----------
SERVER_USER="${SUDO_USER:-$USER}"   # usuario añadido a docker/zerotier
INSTALL_PIHOLE="yes"                # "no" para omitir Pi-hole
INSTALL_CASAOS="yes"                # "no" para omitir CasaOS
AUTO_REBOOT="yes"                   # "no" para reinicio manual
# ---------------------------------

###################################
# 1. Base APT + actualizaciones
###################################
install_base() {
  LOG "Actualizando APT y herramientas básicas…"
  apt update && apt -y full-upgrade
  apt install -y git curl gnupg lsb-release nano \
                 ca-certificates software-properties-common \
                 apt-transport-https
}

###################################
# 2. Zsh + Oh-My-Zsh + autosuggestions
###################################
install_shell() {
  LOG "Instalando Zsh y Oh-My-Zsh…"
  apt install -y zsh
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
      "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
  sed -i 's/^plugins=(\(.*\))/plugins=(\1 zsh-autosuggestions)/' "${HOME}/.zshrc"
  chsh -s "$(command -v zsh)" "$SERVER_USER"
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
  snap install core --classic >/dev/null
  snap install certbot --classic
  ln -sf /snap/bin/certbot /usr/bin/certbot
}

###################################
# 5. Docker Engine + compose-plugin
###################################
install_docker() {
  LOG "Instalando Docker Engine…"
  install -m0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
       gpg --dearmor -o /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
       tee /etc/apt/sources.list.d/docker.list >/dev/null
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
  usermod -aG zerotier-one "$SERVER_USER"
  systemctl enable --now zerotier-one
}

###################################
# 7. Portainer
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
# 9. Pi-hole (opcional)
###################################
install_pihole() {
  [[ "$INSTALL_PIHOLE" == "no" ]] && return
  LOG "Instalando Pi-hole… (modo unattended)"
  export PIHOLE_SKIP_OS_CHECK=true
  curl -sSL https://install.pi-hole.net | bash
}

###################################
# 10. Plex Media Server (nativo)
###################################
install_plex() {
  LOG "Instalando Plex Media Server…"
  install -m0755 -d /etc/apt/keyrings
  curl https://downloads.plex.tv/plex-keys/PlexSign.key | \
       gpg --dearmor -o /etc/apt/keyrings/plex.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/plex.asc] \
https://downloads.plex.tv/repo/deb public main" | \
       tee /etc/apt/sources.list.d/plexmediaserver.list >/dev/null
  apt update
  apt install -y plexmediaserver
  systemctl enable --now plexmediaserver
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

  LOG \"Instalación completa.\"
  LOG \"Accesos:\\n  • Portainer → https://<IP>:9443\\n  • CasaOS → http://<IP>\\n  • Plex → http://<IP>:32400/web\\n  • Pi-hole → http://<IP>/admin\"

  if [[ \"$AUTO_REBOOT\" == \"yes\" ]]; then
    LOG \"Reiniciando en 10 s… (Ctrl-C para abortar)\"
    sleep 10 && reboot
  else
    printf \"\\n¿Deseas reiniciar ahora? [y/N]: \"
    read -r REPLY
    if [[ ${REPLY,,} == \"y\" ]]; then
      LOG \"Reiniciando…\"
      reboot
    else
      LOG \"No se reinició. Hazlo manualmente cuando quieras.\"
    fi
  fi
}

main \"$@\"
SCRIPT
chmod +x auto_server_setup.sh
