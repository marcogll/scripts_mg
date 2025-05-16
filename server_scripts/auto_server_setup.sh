#!/usr/bin/env bash
# auto_server_setup_emoji_top.sh — 2025-05-02
# • Ubuntu 22.04 / 24.04 “home-server” all-in-one:
#   Configuración Wi-Fi • Docker + Portainer + CapRover + Nginx Proxy Manager • Plex • Pi-hole • CasaOS
#   Samba share • Oh-My-Zsh (plugins + alias)
#   Utilidades básicas (SSH, net-tools, htop, ufw, fail2ban, avahi)
#   Visual: barra de progreso con emojis 🚀🛠️

set -euo pipefail

##############################################################################
# Barra de progreso estética                                                    #
##############################################################################
STEPS_TOTAL=17
STEP_NOW=0
bar() {
  clear
  local width=30
  local filled=$(( STEP_NOW * width / STEPS_TOTAL ))
  local empty=$(( width - filled ))
  local gauge
  gauge="$(printf '%0.s🟩' $(seq 1 $filled))$(printf '%0.s⬜' $(seq 1 $empty))"
  printf "\n %s %3d%% [ %s ]\n" "$gauge" $(( STEP_NOW * 100 / STEPS_TOTAL )) "$1"
}
next() { STEP_NOW=$(( STEP_NOW + 1 )); bar "$1"; }
LOG() { echo -e "\033[1;32m▶ $*\033[0m"; }

##############################################################################
# 0. Root check                                                              #
##############################################################################
[[ $(id -u) -eq 0 ]] || { echo "⚠️  Run as root or sudo." >&2; exit 1; }

##############################################################################
# 1. Wi-Fi Configuration                                                      #
##############################################################################
next "📶 Wi-Fi"
# Detect wireless adapter
if lspci | grep -i wireless >/dev/null || lsusb | grep -i wireless >/dev/null; then
  LOG "Adaptador Wi-Fi detectado"
  apt update && apt install -y wpasupplicant wireless-tools
  read -rp "➤ SSID de la red Wi-Fi: " WIFI_SSID
  read -rsp "➤ Contraseña Wi-Fi: " WIFI_PASS; echo
  cat > /etc/wpa_supplicant/wpa_supplicant.conf <<EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=MX

network={
    ssid="${WIFI_SSID}"
    psk="${WIFI_PASS}"
}
EOF
  chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf
  systemctl enable wpa_supplicant
  systemctl start wpa_supplicant
  # Try obtaining IP
  dhclient -v wlan0 || dhclient -v wlp2s0 || true
  LOG "Wi-Fi configurado"
else
  LOG "No se detectó adaptador Wi-Fi; omitiendo configuración"
fi

##############################################################################
# 2. Hardware info (neofetch)                                                 #
##############################################################################
next "📊 Hardware Info"
command -v neofetch >/dev/null 2>&1 || apt install -y neofetch
clear && neofetch

##############################################################################
# 3. Hostname & local domain                                                  #
##############################################################################
next "🖥️  Hostname & Domain"
DEFAULT_HOST="$(hostname)"
read -rp "➤ New hostname [${DEFAULT_HOST}]: " NEW_HOST
NEW_HOST="${NEW_HOST:-$DEFAULT_HOST}"
echo "$NEW_HOST" >/etc/hostname
sed -i "s/127.0.1.1.*/127.0.1.1\t$NEW_HOST/" /etc/hosts || true
hostname "$NEW_HOST"

read -rp "➤ Configure local domain? (e.g., server.local) [Y/n]: " DOM
if [[ ${DOM,,} =~ ^y ]]; then
  read -rp "➤ Domain: " LOCAL_DOMAIN
  echo "127.0.0.1\t$LOCAL_DOMAIN" >>/etc/hosts
  LOG "Domain local set: $LOCAL_DOMAIN"
fi

##############################################################################
# 4. Basic utilities                                                          #
##############################################################################
next "🛠️  Utilities"
apt update && apt -y upgrade
apt install -y \
  openssh-server net-tools htop curl wget gnupg2 ca-certificates lsb-release \
  avahi-daemon ufw fail2ban

##############################################################################
# 5. Docker install & permissions                                             #
##############################################################################
next "🐳 Docker"
apt install -y apt-transport-https software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  >/etc/apt/sources.list.d/docker.list
apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable docker && systemctl start docker
# Allow docker without sudo
groupadd docker || true
read -rp "➤ User to add to docker group [${SUDO_USER:-$USER}]: " DU
DOCKER_USER="${DU:-${SUDO_USER:-$USER}}"
usermod -aG docker "$DOCKER_USER"

##############################################################################
# 6. Portainer                                                                #
##############################################################################
next "🔧 Portainer"
docker volume create portainer_data
docker run -d --name portainer \
  --restart=always -p 9443:9443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data portainer/portainer-ce:latest
LOG "Portainer: https://$NEW_HOST:9443"

##############################################################################
# 7. CapRover                                                                #
##############################################################################
next "🚀 CapRover"
docker run -d --name caprover --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /captain:/captain \
  -p 80:80 -p 443:443 -p 3000:3000 caprover/caprover:latest
LOG "CapRover: http://$NEW_HOST:3000"

##############################################################################
# 8. Nginx Proxy Manager                                                      #
##############################################################################
next "🌐 NPM"
docker run -d --name nginx-proxy-manager --restart=unless-stopped \
  -p 80:80 -p 443:443 -p 81:81 \
  -v /opt/npm/data:/data \
  -v /opt/npm/letsencrypt:/etc/letsencrypt \
  jc21/nginx-proxy-manager:latest
LOG "Nginx Proxy Manager: http://$NEW_HOST:81"

##############################################################################
# 9. Plex                                                                     #
##############################################################################
next "🎞️  Plex"
docker run -d --name plex --restart=unless-stopped \
  --network=host \
  -e TZ="America/Monterrey" \
  -v /srv/plex/config:/config \
  -v /srv/plex/media:/data plexinc/pms-docker:latest
LOG "Plex: http://$NEW_HOST:32400/web"

##############################################################################
# 10. Pi-hole                                                                  #
##############################################################################
next "🚫 Pi-hole"
docker run -d --name pihole --restart=unless-stopped \
  -p 53:53/tcp -p 53:53/udp -p 8080:80 \
  -e TZ="America/Monterrey" \
  -e WEBPASSWORD="changeme" \
  -v /opt/pihole/etc-pihole:/etc/pihole \
  -v /opt/pihole/etc-dnsmasq.d:/etc/dnsmasq.d pihole/pihole:latest
LOG "Pi-hole: http://$NEW_HOST:8080"

##############################################################################
# 11. CasaOS                                                                  #
##############################################################################
next "🏠 CasaOS"
curl -fsSL https://get.casaos.io | bash
LOG "CasaOS: http://$NEW_HOST"

##############################################################################
# 12. Samba share                                                             #
##############################################################################
next "📁 Samba"
read -rp "➤ Folder to share (full path): " SMB_DIR
mkdir -p "$SMB_DIR"
read -rp "➤ Samba user: " SMB_USER
read -srp "➤ Samba password: " SMB_PASS; echo
adduser --gecos "" --disabled-password "$SMB_USER"
echo "$SMB_USER:$SMB_PASS" | chpasswd
(echo "$SMB_PASS"; echo "$SMB_PASS") | smbpasswd -s -a "$SMB_USER"
cat >>/etc/samba/smb.conf <<EOF
[$SMB_USER]
  path = $SMB_DIR
  browseable = yes
  read only = no
  valid users = $SMB_USER
EOF
systemctl restart smbd nmbd
LOG "Samba share: //$NEW_HOST/$SMB_USER"

##############################################################################
# 13. Oh My Zsh + plugins + alias                                             #
##############################################################################
next "💎 Oh My Zsh"
apt install -y zsh git
sudo -u "$DOCKER_USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
chsh -s $(which zsh) "$DOCKER_USER"
sudo -u "$DOCKER_USER" git clone https://github.com/zsh-users/zsh-autosuggestions \
  "/home/$DOCKER_USER/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
sudo -u "$DOCKER_USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  "/home/$DOCKER_USER/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
sed -i 's/plugins=(/plugins=(docker docker-compose zsh-autosuggestions zsh-syntax-highlighting /' "/home/$DOCKER_USER/.zshrc"
LOG "Oh My Zsh configured for $DOCKER_USER"

##############################################################################
# 14. Firewall & Fail2Ban                                                     #
##############################################################################
next "🛡️ Firewall"
ufw allow OpenSSH && ufw allow 81 && ufw allow 3000 && ufw allow 32400 && ufw allow 8080 && ufw --force enable
systemctl enable fail2ban && systemctl start fail2ban

##############################################################################
# 15. Final summary                                                          #
##############################################################################
next "✅ Summary"
echo
LOG "Access your services:"
echo " - Portainer → https://$NEW_HOST:9443"
echo " - CapRover → http://$NEW_HOST:3000"
echo " - NPM → http://$NEW_HOST:81"
echo " - Plex → http://$NEW_HOST:32400/web"
echo " - Pi-hole → http://$NEW_HOST:8080"
echo " - CasaOS → http://$NEW_HOST"
echo " - Samba → //$NEW_HOST/$SMB_USER"

##############################################################################
# 16. Reboot if desired                                                       #
##############################################################################
read -rp "🔄 Reboot now? [y/N]: " REBOOT
if [[ ${REBOOT,,} == y ]]; then
  reboot
else
  LOG "Setup complete. Reboot manually to apply all changes."
fi
