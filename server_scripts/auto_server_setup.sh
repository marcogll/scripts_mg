#!/usr/bin/env bash
# auto_server_setup_emoji_top.sh — 2025-05-02
# • Ubuntu 22.04 / 24.04 “home-server” all-in-one:
#   Docker + Portainer + Docker Desktop • Plex • Pi-hole • CasaOS
#   Samba share • Oh-My-Zsh (plugins + alias)
#   Barra de progreso con emojis anclada arriba.  🚀🛠️

set -euo pipefail

##############################################################################
# Barra de progreso anclada                                                  #
##############################################################################
STEPS_TOTAL=12          # ¡actualiza si añades/eliminas “next”!
STEP_NOW=0
bar() {
  clear
  local width=20
  local filled=$(( STEP_NOW*width / STEPS_TOTAL ))
  local empty=$(( width - filled ))
  local gauge
  gauge="$(printf '%0.s🟩' $(seq 1 $filled))$(printf '%0.s⬜' $(seq 1 $empty))"
  printf "%s %3d%%  %s\n\n" "$gauge" $(( STEP_NOW*100 / STEPS_TOTAL )) "$1"
}
next() { STEP_NOW=$(( STEP_NOW + 1 )); bar "$1"; }
LOG()  { echo -e "\033[1;32m▶ $*\033[0m"; }

##############################################################################
# Comprobación de root                                                       #
##############################################################################
[[ $(id -u) -eq 0 ]] || { echo "⚠️  Ejecútame con sudo o como root." >&2; exit 1; }

##############################################################################
# 0. Análisis de hardware (tipo fastfetch)                                   #
##############################################################################
next "📊 Análisis de hardware"
neofetch || sudo apt install -y neofetch
clear && neofetch

##############################################################################
# 1. Hostname y configuración de red                                         #
##############################################################################
next "🖥️  Configurando hostname"
DEFAULT_HOST="$(hostname)"
read -rp "➤ Nuevo hostname [$DEFAULT_HOST]: " NEW_HOST
NEW_HOST="${NEW_HOST:-$DEFAULT_HOST}"
echo "$NEW_HOST" > /etc/hostname
sed -i "s/127.0.1.1.*/127.0.1.1\t$NEW_HOST/" /etc/hosts || true
hostname "$NEW_HOST"

read -rp "➤ Deseas configurar un dominio local? (e.g., server.local) [Y/n]: " dom
if [[ ${dom,,} =~ ^y ]]; then
    read -rp "➤ Nombre del dominio (e.g., server.local): " LOCAL_DOMAIN
    echo "127.0.0.1\t$LOCAL_DOMAIN" >> /etc/hosts
    echo "Dominio local configurado: $LOCAL_DOMAIN"
fi

##############################################################################
# 2. Permisos para Docker sin sudo                                           #
##############################################################################
next "🔓 Configurando Docker sin sudo"
groupadd docker || true
usermod -aG docker "$SERVER_USER"
newgrp docker

##############################################################################
# 3. Preguntas iniciales                                                     #
##############################################################################
next "❓ Preguntas iniciales"
DEFAULT_USER="${SUDO_USER:-$USER}"
read -rp "➤ Usuario Linux a configurar [$DEFAULT_USER]: " u
SERVER_USER="${u:-$DEFAULT_USER}"
read -rp "➤ Instalar Pi-hole? [Y/n]: " p
INSTALL_PIHOLE="$( [[ ${p,,} =~ ^n ]] && echo no || echo yes )"
read -rp "➤ Instalar CasaOS? [Y/n]: " c
INSTALL_CASAOS="$( [[ ${c,,} =~ ^n ]] && echo no || echo yes )"
read -rp "➤ Reinicio automático al final? [Y/n]: " r
AUTO_REBOOT="$( [[ ${r,,} =~ ^n ]] && echo no || echo yes )"

##############################################################################
# 4. Paquetes base (lista + descripción)                                     #
##############################################################################
next "📦 Instalando paquetes base"
declare -A PKG_DESC=(
  [git]="control de versiones"             [curl]="cliente HTTP(S)"
  [gnupg]="cifrado/Firmas GPG"             [lsb-release]="info de la distro"
  [nano]="editor de texto"                 [build-essential]="compilación C/C++"
  [ca-certificates]="certificados SSL"     [software-properties-common]="PPAs"
  [apt-transport-https]="APT sobre HTTPS"  [fontconfig]="caché fuentes (fc-cache)"
  [zsh]="shell Zsh"                        [fzf]="búsqueda fuzzy"
  [btop]="monitor de recursos"             [ufw]="firewall sencillo"
  [unzip]="descompresor ZIP"               [whiptail]="menús en shell"
)
echo "• Se instalarán:"
for p in "${!PKG_DESC[@]}"; do printf "  - %-18s %s\n" "$p" "${PKG_DESC[$p]}"; done
export DEBIAN_FRONTEND=noninteractive
apt update && apt -y full-upgrade
apt install -y "${!PKG_DESC[@]}"

##############################################################################
# 5. Oh-My-Zsh + plugins + alias                                             #
##############################################################################
next "💎 Oh-My-Zsh + plugins/alias"
sudo -u "$SERVER_USER" bash -c \
  'curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
  | bash -s -- --unattended'

sudo -u "$SERVER_USER" git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
  "/home/$SERVER_USER/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
sudo -u "$SERVER_USER" git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
  "/home/$SERVER_USER/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

ZSHRC="/home/$SERVER_USER/.zshrc"
sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting colorize)/' "$ZSHRC"
grep -qxF "alias cls='clear'" "$ZSHRC" || cat >>"$ZSHRC" <<'EOF'

# --- Custom aliases ---
alias cls='clear'
alias clima='curl wttr.in/Saltillo'
alias pip='pip3'
export PATH=$HOME/.local/bin:$HOME/.npm-global/bin:$PATH
EOF
chsh -s "$(command -v zsh)" "$SERVER_USER"
