#!/usr/bin/env bash
# auto_server_setup_emoji.sh — 2025-05-02
# Home-server Ubuntu 22.04/24.04 con Docker, Portainer, ZeroTier, Tailscale,
# Plex, Samba, Oh-My-Zsh + plugins, Oh-My-Posh (clean-detailed) + Meslo Nerd Font.
# Incluye barra de progreso con emojis.  🚀🛠️

set -euo pipefail

################################################################################
# Barra de progreso con emojis                                                 #
################################################################################
STEPS_TOTAL=12   # actualiza si cambias el número de “next”
STEP_NOW=0
bar() {
  local width=20
  local filled=$(( STEP_NOW*width/STEPS_TOTAL ))
  local empty=$(( width-filled ))
  local bar
  bar="$(printf '%0.s🟩' $(seq 1 $filled))"
  bar+="$(printf '%0.s⬜' $(seq 1 $empty))"
  local pct=$(( STEP_NOW*100/STEPS_TOTAL ))
  printf "\r%s %3d%%  %s\n" "$bar" "$pct" "$1"
}

next() { STEP_NOW=$(( STEP_NOW+1 )); bar "$1"; }
LOG()  { echo -e "\n\033[1;32m▶ $*\033[0m"; }

################################################################################
# Comprobación de root                                                         #
################################################################################
if [[ "$(id -u)" -ne 0 ]]; then
  echo "⚠️  Ejecuta este script con sudo o como root." >&2
  exit 1
fi

################################################################################
# 0. Hostname                                                                  #
################################################################################
next "🖥️  Configurando hostname"
read -rp "➤ Nuevo hostname: " NEW_HOST
if [[ -n "$NEW_HOST" ]]; then
  echo "$NEW_HOST" > /etc/hostname
  sed -i "s/127.0.1.1.*/127.0.1.1\t$NEW_HOST/" /etc/hosts || true
  hostname "$NEW_HOST"
fi

################################################################################
# 1. Preguntas iniciales                                                       #
################################################################################
next "❓ Preguntas iniciales"
DEFAULT_USER="${SUDO_USER:-$USER}"
read -rp "➤ Usuario Linux a configurar [$DEFAULT_USER]: " TMP
SERVER_USER="${TMP:-$DEFAULT_USER}"

read -rp "➤ Instalar Pi-hole? [Y/n]: " pih
INSTALL_PIHOLE="$( [[ ${pih,,} =~ ^n ]] && echo no || echo yes )"

read -rp "➤ Instalar CasaOS? [Y/n]: " cas
INSTALL_CASAOS="$( [[ ${cas,,} =~ ^n ]] && echo no || echo yes )"

read -rp "➤ Reinicio automático al final? [Y/n]: " reb
AUTO_REBOOT="$( [[ ${reb,,} =~ ^n ]] && echo no || echo yes )"

################################################################################
# 2. Paquetes base + Zsh + plugins + alias                                     #
################################################################################
next "📦 Instalando paquetes base"
export DEBIAN_FRONTEND=noninteractive
apt update && apt -y full-upgrade
apt install -y git curl gnupg lsb-release nano build-essential \
               ca-certificates software-properties-common \
               apt-transport-https zsh fzf btop ufw unzip whiptail

next "💎 Oh-My-Zsh + plugins"
sudo -u "$SERVER_USER" sh -c \
  'curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash -s -- --unattended'

sudo -u "$SERVER_USER" git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
  "/home/$SERVER_USER/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
sudo -u "$SERVER_USER" git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
  "/home/$SERVER_USER/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

ZSHRC="/home/$SERVER_USER/.zshrc"
sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting colorize)/' "$ZSHRC"

grep -qxF "alias cls='clear'" "$ZSHRC" || cat >> "$ZSHRC" <<'EOF'

# --- Custom aliases ---
alias cls='clear'
alias clima='curl wttr.in/Saltillo'
alias pip='pip3'
export PATH=$HOME/.local/bin:$HOME/.npm-global/bin:$PATH
EOF

chsh -s "$(command -v zsh)" "$SERVER_USER"

################################################################################
# 3. Oh-My-Posh + Meslo Nerd Font                                              #
################################################################################
next "🎨 Oh-My-Posh + Meslo"
curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin

oh-my-posh font install meslo --path /usr/local/share/fonts
fc-cache -f

sudo -u "$SERVER_USER" mkdir -p "/home/$SERVER_USER/.poshthemes"
curl -fsSL https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/clean-detailed.omp.json \
  -o "/home/$SERVER_USER/.poshthemes/clean-detailed.omp.json"
chmod 644 "/home/$SERVER_USER/.poshthemes/clean-detailed.omp.json"

OMP_LINE='eval "$(oh-my-posh init zsh --config ~/.poshthemes/clean-detailed.omp.json)"'
grep -qxF "$OMP_LINE" "$ZSHRC" || echo "$OMP_LINE" >> "$ZSHRC"

################################################################################
# 4. Certbot                                                                   #
################################################################################
next "🔐 Certbot"
snap install core --classic >/dev/null || true
snap refresh core
snap install --classic certbot
ln -sf /snap/bin/certbot /usr/bin/certbot

################################################################################
# 5. Docker + Portainer + ZeroTier + Tailscale                                 #
################################################################################
next "🐳 Docker & friends"
install -m0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
source /etc/os-release
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $VERSION_CODENAME stable" \
  > /etc/apt/sources.list.d/docker.list
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker "$SERVER_USER"

docker volume create portainer_data
docker run -d --name portainer \
  -p 8000:8000 -p 9443:9443 \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

curl -s https://install.zerotier.com | bash
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --ssh --accept-dns=false || true

################################################################################
# 6. CasaOS (opcional)                                                         #
################################################################################
if [[ "$INSTALL_CASAOS" == "yes" ]]; then
  next "🏠 CasaOS"
  curl -fsSL https://get.casaos.io | bash
fi

################################################################################
# 7. Pi-hole (opcional)                                                        #
################################################################################
if [[ "$INSTALL_PIHOLE" == "yes" ]]; then
  next "🚫 Pi-hole"
  export PIHOLE_SKIP_OS_CHECK=true
  curl -sSL https://install.pi-hole.net | bash -s -- --unattended
fi

################################################################################
# 8. Plex Media Server                                                         #
################################################################################
next "🎞️  Plex"
curl -fsSL https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/plex.gpg
echo "deb [signed-by=/etc/apt/trusted.gpg.d/plex.gpg] https://downloads.plex.tv/repo/deb/ public main" \
  > /etc/apt/sources.list.d/plexmediaserver.list
apt update && apt install -y plexmediaserver

################################################################################
# 9. Samba                                                                     #
################################################################################
next "📁 Samba"
apt install -y samba
read -rp "➤ Carpeta a compartir (ruta completa): " SAMBA_DIR
mkdir -p "$SAMBA_DIR"
read -rp "➤ Usuario Samba: " SAMBA_USER
read -srp "➤ Contraseña Samba: " SAMBA_PASS; echo
adduser --gecos "" --disabled-password "$SAMBA_USER"
echo "$SAMBA_USER:$SAMBA_PASS" | chpasswd
(echo "$SAMBA_PASS"; echo "$SAMBA_PASS") | smbpasswd -s -a "$SAMBA_USER"
cat >> /etc/samba/smb.conf <<EOF

[$SAMBA_USER-share]
   path = $SAMBA_DIR
   browseable = yes
   read only = no
   guest ok = no
   valid users = $SAMBA_USER
EOF
systemctl restart smbd nmbd

################################################################################
# 10. Resumen final                                                            #
################################################################################
next "✅ Resumen"
echo -e "\n🔑 Accesos principales:"
echo " • Portainer  → https://$NEW_HOST:9443"
echo " • Plex       → http://$NEW_HOST:32400/web"
[[ "$INSTALL_PIHOLE" == "yes" ]] && echo " • Pi-hole    → http://$NEW_HOST/admin"
[[ "$INSTALL_CASAOS" == "yes" ]] && echo " • CasaOS     → http://$NEW_HOST"
echo " • Samba path → $SAMBA_DIR  (usuario: $SAMBA_USER)"
echo -e "\n⚠️  Selecciona la fuente «MesloLGS NF» en tu terminal local para ver Oh-My-Posh."

if [[ "$AUTO_REBOOT" == "yes" ]]; then
  echo -e "\n🔄 Reiniciando en 10 s…  (Ctrl-C para abortar)"
  sleep 10 && reboot
else
  read -rp $'\n¿Reiniciar ahora? [y/N]: ' ans
  [[ ${ans,,} == y ]] && reboot || echo "🚀 Instalación completada sin reinicio."
fi
