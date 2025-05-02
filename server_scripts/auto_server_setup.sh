#!/usr/bin/env bash
# auto_server_setup_emoji_top.sh — 2025-05-02
# Home-server Ubuntu 22.04/24.04 con Docker, Portainer, ZeroTier, Tailscale,
# Plex, Samba, Oh-My-Zsh (plugins + alias) y Oh-My-Posh (tema clean-detailed)
# + Meslo Nerd Font.  Barra de progreso con emojis anclada arriba.  🚀🛠️

set -euo pipefail

##############################################################################
# Barra de progreso «pegada»                                                 #
##############################################################################
STEPS_TOTAL=12
STEP_NOW=0
bar() {
  clear
  local width=20                # ancho de la barra
  local filled=$(( STEP_NOW*width/STEPS_TOTAL ))
  local empty=$(( width-filled ))
  local line
  line="$(printf '%0.s🟩' $(seq 1 $filled))$(printf '%0.s⬜' $(seq 1 $empty))"
  printf "%s %3d%%  %s\n\n" "$line" $(( STEP_NOW*100/STEPS_TOTAL )) "$1"
}
next() { STEP_NOW=$(( STEP_NOW+1 )); bar "$1"; }
LOG()  { echo -e "\033[1;32m▶ $*\033[0m"; }

##############################################################################
# Comprobación de root                                                       #
##############################################################################
[[ $(id -u) -eq 0 ]] || { echo "⚠️  Ejecuta con sudo o como root." >&2; exit 1; }

##############################################################################
# 0. Hostname                                                                 #
##############################################################################
next "🖥️  Configurando hostname"
DEFAULT_HOST="$(hostname)"
read -rp "➤ Nuevo hostname [$DEFAULT_HOST]: " NEW_HOST
NEW_HOST="${NEW_HOST:-$DEFAULT_HOST}"
echo "$NEW_HOST" >/etc/hostname
sed -i "s/127.0.1.1.*/127.0.1.1\t$NEW_HOST/" /etc/hosts || true
hostname "$NEW_HOST"

##############################################################################
# 1. Preguntas iniciales                                                      #
##############################################################################
next "❓ Preguntas iniciales"
DEFAULT_USER="${SUDO_USER:-$USER}"
read -rp "➤ Usuario Linux a configurar [$DEFAULT_USER]: " tmp; SERVER_USER="${tmp:-$DEFAULT_USER}"
read -rp "➤ Instalar Pi-hole? [Y/n]: "  p; INSTALL_PIHOLE="$( [[ ${p,,} =~ ^n ]] && echo no || echo yes )"
read -rp "➤ Instalar CasaOS? [Y/n]: "   c; INSTALL_CASAOS="$( [[ ${c,,} =~ ^n ]] && echo no || echo yes )"
read -rp "➤ Reinicio automático al final? [Y/n]: " r; AUTO_REBOOT="$( [[ ${r,,} =~ ^n ]] && echo no || echo yes )"

##############################################################################
# 2. Paquetes base (lista con descripción)                                    #
##############################################################################
next "📦 Instalando paquetes base"
declare -A BASE_PKGS=(
  [git]="control de versiones"
  [curl]="cliente HTTP(S)"
  [gnupg]="cifrado/Firmas GPG"
  [lsb-release]="info versión Ubuntu"
  [nano]="editor de texto"
  [build-essential]="herramientas de compilación"
  [ca-certificates]="certificados SSL"
  [software-properties-common]="gestión de repositorios"
  [apt-transport-https]="APT vía HTTPS"
  [fontconfig]="caché de fuentes (fc-cache)"
  [zsh]="shell Zsh"
  [fzf]="búsqueda fuzzy"
  [btop]="monitor recursos"
  [ufw]="firewall sencillo"
  [unzip]="descompresor ZIP"
  [whiptail]="menús shell"
)
echo "• Se instalarán:"
for pkg in "${!BASE_PKGS[@]}"; do printf "  - %-15s %s\n" "$pkg" "${BASE_PKGS[$pkg]}"; done
export DEBIAN_FRONTEND=noninteractive
apt update && apt -y full-upgrade
apt install -y "${!BASE_PKGS[@]}"

##############################################################################
# 3. Oh-My-Zsh + plugins + alias                                              #
##############################################################################
next "💎 Oh-My-Zsh + plugins/alias"
sudo -u "$SERVER_USER" bash -c \
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

##############################################################################
# 4. Oh-My-Posh + Meslo Nerd Font (manual)                                    #
##############################################################################
next "🎨 Oh-My-Posh + Meslo"
curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin
TMPF=$(mktemp -d)
curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Meslo.zip -o "$TMPF/meslo.zip"
unzip -q "$TMPF/meslo.zip" -d "$TMPF"
mkdir -p /usr/local/share/fonts && cp "$TMPF"/*.ttf /usr/local/share/fonts/
fc-cache -f && rm -rf "$TMPF"
sudo -u "$SERVER_USER" mkdir -p "/home/$SERVER_USER/.poshthemes"
curl -fsSL https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/clean-detailed.omp.json \
  -o "/home/$SERVER_USER/.poshthemes/clean-detailed.omp.json"
chmod 644 "/home/$SERVER_USER/.poshthemes/clean-detailed.omp.json"
OMP_LINE='eval "$(oh-my-posh init zsh --config ~/.poshthemes/clean-detailed.omp.json)"'
grep -qxF "$OMP_LINE" "$ZSHRC" || echo "$OMP_LINE" >> "$ZSHRC"

##############################################################################
# 5. Certbot                                                                  #
##############################################################################
next "🔐 Certbot"
snap install core --classic >/dev/null || true
snap refresh core
snap install --classic certbot
ln -sf /snap/bin/certbot /usr/bin/certbot

##############################################################################
# 6. Docker + Portainer + ZeroTier + Tailscale                                #
##############################################################################
next "🐳 Docker, Portainer, ZeroTier, Tailscale"
install -m0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
source /etc/os-release
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $VERSION_CODENAME stable" >/etc/apt/sources.list.d/docker.list
apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker "$SERVER_USER"
docker volume create portainer_data
docker run -d --name portainer -p 8000:8000 -p 9443:9443 --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data \
  portainer/portainer-ce:latest
curl -s https://install.zerotier.com | bash
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --ssh --accept-dns=false || true

##############################################################################
# 7. CasaOS (opcional)                                                        #
##############################################################################
[[ $INSTALL_CASAOS == yes ]] && { next "🏠 CasaOS"; curl -fsSL https://get.casaos.io | bash; }

##############################################################################
# 8. Pi-hole (opcional)                                                       #
##############################################################################
[[ $INSTALL_PIHOLE == yes ]] && { next "🚫 Pi-hole"; export PIHOLE_SKIP_OS_CHECK=true; curl -sSL https://install.pi-hole.net | bash -s -- --unattended; }

##############################################################################
# 9. Plex Media Server                                                        #
##############################################################################
next "🎞️  Plex"
curl -fsSL https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/plex.gpg
echo "deb [signed-by=/etc/apt/trusted.gpg.d/plex.gpg] https://downloads.plex.tv/repo/deb/ public main" >/etc/apt/sources.list.d/plexmediaserver.list
apt update && apt install -y plexmediaserver

##############################################################################
# 10. Samba                                                                   #
##############################################################################
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

##############################################################################
# 11. Resumen                                                                 #
##############################################################################
next "✅ Resumen"
echo -e "🔑 Accesos:"
echo " • Portainer  → https://$NEW_HOST:9443"
echo " • Plex       → http://$NEW_HOST:32400/web"
[[ $INSTALL_PIHOLE == yes ]] && echo " • Pi-hole    → http://$NEW_HOST/admin"
[[ $INSTALL_CASAOS == yes ]] && echo " • CasaOS     → http://$NEW_HOST"
echo " • Samba path → $SAMBA_DIR  (usuario: $SAMBA
