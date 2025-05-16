#!/usr/bin/env bash
# revert_auto_server_setup.sh — Revertir auto_server_setup_emoji_top
# Este script deshace las acciones del instalador de servidor:
# - Detiene y elimina contenedores Docker
# - Elimina imágenes y volúmenes Docker asociados
# - Desinstala Docker, Portainer, CapRover, NPM, Plex, Pi-hole, CasaOS
# - Restaura configuración de red y hostname
# - Elimina usuario de Samba y limpia smb.conf
# - Desinstala Oh My Zsh y restaura shell por defecto
# - Elimina paquetes básicos instalados
# - Restablece firewall (ufw) y Fail2Ban

set -euo pipefail

LOG() { echo -e "\033[1;31m[REVERT]\033[0m $*"; }

# 1. Parar y eliminar contenedores Docker
LOG "Deteniendo y eliminando contenedores..."
containers=(portainer caprover nginx-proxy-manager plex pihole)
for c in "${containers[@]}"; do
  if docker ps -a --format '{{.Names}}' | grep -q "^${c}$"; then
    docker stop "$c" || true
    docker rm -f "$c" || true
    LOG "→ Contenedor $c eliminado"
  fi
done

# 2. Eliminar volúmenes
LOG "Eliminando volúmenes..."
volumes=(portainer_data)
for v in "${volumes[@]}"; do
  docker volume rm "$v" || true
  LOG "→ Volumen $v eliminado"
done

# 3. Desinstalar Docker Engine
LOG "Desinstalando Docker Engine..."
systemctl stop docker
systemctl disable docker
apt purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
apt autoremove -y
rm -f /etc/apt/keyrings/docker.gpg /etc/apt/sources.list.d/docker.list
LOG "→ Docker desinstalado"

# 4. Restaurar grupo docker
LOG "Restaurando grupo docker..."
if getent group docker >/dev/null; then
  for u in $(getent group docker | cut -d: -f4 | tr ',' ' '); do
    gpasswd -d "$u" docker || true
  done
  groupdel docker || true
  LOG "→ Grupo docker eliminado"
fi

# 5. Desinstalar paquetes básicos
LOG "Desinstalando paquetes básicos..."
apt purge -y neofetch net-tools htop curl wget gnupg2 ca-certificates lsb-release \
  avahi-daemon ufw fail2ban openssh-server
apt autoremove -y
LOG "→ Paquetes básicos eliminados"

# 6. Restablecer firewall y Fail2Ban
LOG "Restableciendo firewall y Fail2Ban..."
ufw --force reset
systemctl disable fail2ban
systemctl stop fail2ban
apt purge -y ufw fail2ban
LOG "→ Firewall y Fail2Ban desinstalados"

# 7. Eliminar CasaOS
LOG "Eliminando CasaOS..."
if command -v casaos >/dev/null; then
  systemctl stop casaos.service casaos-admin.service || true
  rm -rf /opt/casaos ~/.casaos
  LOG "→ Archivos de CasaOS eliminados"
fi

# 8. Eliminar Samba share y usuario
LOG "Eliminando Samba share y usuario..."
read -rp "Nombre de usuario Samba a eliminar: " SMB_USER
sed -i "/\[$SMB_USER\]/,/^$/d" /etc/samba/smb.conf || true
systemctl restart smbd nmbd
userdel -r "$SMB_USER" || true
LOG "→ Samba eliminado para usuario $SMB_USER"

# 9. Restaurar hostname y hosts
LOG "Restaurando hostname original..."
# Sustituye manualmente si es necesario
sed -i "s/^127.0.1.1.*/127.0.1.1\t$(hostname -f)/" /etc/hosts || true

# 10. Desinstalar Oh My Zsh
LOG "Eliminando Oh My Zsh y restaurando shell..."
read -rp "Usuario Zsh a restaurar shell (e.g. marco): " RUSER
chsh -s /bin/bash "$RUSER"
rm -rf /home/$RUSER/.oh-my-zsh /home/$RUSER/.zshrc
LOG "→ Oh My Zsh desinstalado para $RUSER"

LOG "Revert completo. Reinicia manualmente para aplicar todos los cambios."
