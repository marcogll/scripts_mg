#!/usr/bin/env bash
# auto_server_reset.sh — revierte el home-server a un estado «casi limpio».
# Probado en Ubuntu 22.04 / 24.04.  Requiere sudo/root.

set -euo pipefail

################################################################################
# Barra de progreso básica                                                     #
################################################################################
STEPS_TOTAL=9
STEP=0
progress() {
  local w=20 f=$(( STEP*w/STEPS_TOTAL )) e=$(( w-f ))
  printf "\r%s%*s %3d%%  %s" "$(printf '🟥%.0s' $(seq 1 $f))" $e '' \
         $(( STEP*100/STEPS_TOTAL )) "$1"
}
next() { STEP=$(( STEP+1 )); progress "$1"; echo; }

confirm() {
  read -rp "⚠️  Realmente quieres continuar? (type YES): " ans
  [[ $ans == YES ]] || { echo "Abortado."; exit 1; }
}

[[ $(id -u) -eq 0 ]] || { echo "Ejecuta con sudo/root."; exit 1; }
confirm

################################################################################
# 1. Parar y borrar contenedores                                               #
################################################################################
next "Deteniendo y eliminando contenedores Docker"
if command -v docker &>/dev/null; then
  docker ps -aq | xargs -r docker stop
  docker ps -aq | xargs -r docker rm -f
  docker volume ls -q | grep -E 'portainer|pihole' | xargs -r docker volume rm
fi

################################################################################
# 2. Desinstalar paquetes instalados                                           #
################################################################################
next "Purgando paquetes APT/Snap"
apt purge -y \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
  tailscale zerotier-one certbot python3-certbot-* \
  plexmediaserver samba samba-* cifs-utils mergerfs smartmontools udevil \
  fontconfig fzf btop zsh oh-my-posh \
  || true
snap remove --purge certbot 2>/dev/null || true

################################################################################
# 3. Deshabilitar y borrar servicios de CasaOS                                 #
################################################################################
next "Desinstalando CasaOS"
systemctl stop casaos* rclone.service 2>/dev/null || true
systemctl disable casaos* rclone.service 2>/dev/null || true
rm -rf /etc/systemd/system/casaos* /usr/lib/systemd/system/casaos* /opt/casaos \
       /etc/casaos /var/lib/casaos /usr/bin/casaos* /usr/local/bin/casaos* \
       /etc/systemd/system/rclone.service

################################################################################
# 4. Limpiar configuraciones personalizadas                                    #
################################################################################
next "Limpiando Oh-My-Zsh, plugins y Oh-My-Posh"
USER_HOME="/home/${SUDO_USER:-$USER}"
rm -rf "$USER_HOME/.oh-my-zsh" "$USER_HOME/.poshthemes"
sed -i '/oh-my-posh init/d;/alias cls=/d;/alias clima=/d;/alias pip=/d' "$USER_HOME/.zshrc" || true
chsh -s /bin/bash "${SUDO_USER:-$USER}" || true

################################################################################
# 5. Eliminar fuentes Meslo Nerd Font                                          #
################################################################################
next "Quitando fuentes Meslo Nerd Font"
find /usr/local/share/fonts -type f -name '*MesloLGS NF*.ttf' -delete
fc-cache -f >/dev/null || true

################################################################################
# 6. Purgar dependencias huérfanas y cachés                                    #
################################################################################
next "APT autoremove & autoclean"
apt -y autoremove --purge
apt -y autoclean

################################################################################
# 7. Borrar usuarios y shares Samba                                            #
################################################################################
next "Eliminando usuario Samba y share"
if pdbedit -L | grep -q '^'"$USER"':' ; then
  (echo delete User | smbpasswd -x "$USER") || true
fi
rm -rf /etc/samba/smb.conf /var/lib/samba

################################################################################
# 8. Restaurar hostname opcional                                               #
################################################################################
next "Mantener hostname actual: $(hostname) (no se modifica)"

################################################################################
# 9. Reinicio opcional                                                         #
################################################################################
next "Fin. Sistema casi limpio."
read -rp $'\n¿Reiniciar ahora? [y/N]: ' reboot_ans
[[ ${reboot_ans,,} == y ]] && reboot
echo "🏁 Limpieza completada."
