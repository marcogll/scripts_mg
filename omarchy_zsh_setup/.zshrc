# =============================================================================
#                    CONFIGURACIÓN ZSH - OMARCHY v2.1
# =============================================================================

# --- PATH --------------------------------------------------------------------
typeset -U PATH path
path=(
  $HOME/.local/bin
  $HOME/bin
  $HOME/.npm-global/bin
  $HOME/AppImages
  $HOME/go/bin
  $path
)

# --- Oh My Zsh ---------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="" # Oh My Posh manejará el prompt, así que el tema de OMZ queda vacío.

plugins=(
  git sudo history colorize
  docker docker-compose
  npm node python pip golang
  copypath copyfile
  # Si usas zoxide, no lo añadas aquí, se inicializa más abajo
)

export ZSH_DISABLE_COMPFIX=true
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "$HOME/.zcompcache"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select

# Cargar Oh My Zsh
[ -r "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# Cargar plugins específicos (zsh-autosuggestions y zsh-syntax-highlighting)
[ -r "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
  source "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

[ -r "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \
  source "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# --- Oh My Posh --------------------------------------------------------------
# Asegúrate de que Oh My Posh esté instalado y el tema 'catppuccin.omp.json'
# esté en ~/.poshthemes/
if command -v oh-my-posh >/dev/null 2>&1; then
  if [ -f ~/.poshthemes/catppuccin.omp.json ]; then
    eval "$(oh-my-posh init zsh --config ~/.poshthemes/catppuccin.omp.json)"
  else
    # Fallback si el tema Catppuccin no se encuentra
    eval "$(oh-my-posh init zsh)"
    echo "Advertencia: Tema Catppuccin para Oh My Posh no encontrado en ~/.poshthemes/. Usando el tema por defecto."
  fi
fi

# --- Go ----------------------------------------------------------------------
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"

# --- NVM ---------------------------------------------------------------------
# Es importante que NVM se cargue después de la configuración de PATH,
# pero antes de que intentes usar 'node' o 'npm'.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # Esto carga nvm
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion" # Esto carga nvm bash_completion

# --- Python ------------------------------------------------------------------
alias pip='pip3'
alias python='python3'

venv() {
  case "$1" in
    create) python -m venv .venv && echo "✅ Entorno virtual creado en ./.venv" ;;
    on|activate)
      if [ -f ".venv/bin/activate" ]; then
        . .venv/bin/activate
        echo "🟢 Entorno virtual activado"
      else
        echo "❌ Entorno virtual no encontrado en ./.venv"
      fi
      ;;
    off|deactivate)
      if command -v deactivate &>/dev/null; then
        deactivate 2>/dev/null
        echo "🔴 Entorno virtual desactivado"
      else
        echo "🤷 No hay un entorno virtual activo para desactivar"
      fi
      ;;
    *) echo "Uso: venv [create|on|off|activate|deactivate]" ;;
  esac
}

# --- Aliases -----------------------------------------------------------------
alias cls='clear'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# System info
alias ff='fastfetch' # Requiere fastfetch
alias nf='fastfetch' # Requiere fastfetch

# Arch Linux (si aplica)
alias pacu='sudo pacman -Syu'
alias paci='sudo pacman -S'
alias pacr='sudo pacman -Rns'
alias pacs='pacman -Ss'
alias yayu='yay -Syu' # Requiere yay AUR helper
alias yayi='yay -S'   # Requiere yay AUR helper

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias gcb='git checkout -b'
alias glog='git log --oneline --graph --decorate'
gac(){ git add . && git commit -m "$1"; }

# Docker
# Detecta si se usa 'docker compose' o 'docker-compose'
docker compose version >/dev/null 2>&1 && alias dc='docker compose' || alias dc='docker-compose'
alias d='docker'
alias dps='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlog='docker logs -f'

# NPM
alias nrs='npm run start'
alias nrd='npm run dev'
alias nrb='npm run build'
alias nrt='npm run test'
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install -g'

# Python
alias py='python'
alias pir='pip install -r requirements.txt'
alias pipi='pip install'
alias pipf='pip freeze > requirements.txt'

# ZeroTier
alias zt='sudo zerotier-cli'
alias ztstatus='sudo zerotier-cli listnetworks'
alias ztinfo='sudo zerotier-cli info'

# Clima (requiere curl)
alias clima='curl wttr.in/Saltillo'

# --- Funciones ---------------------------------------------------------------
mkcd(){ mkdir -p "$1" && cd "$1"; }

extract(){
  [ ! -f "$1" ] && echo "No es un archivo" && return 1
  case "$1" in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz) tar xzf "$1" ;;
    *.bz2) bunzip2 "$1" ;;
    *.rar) unrar e "$1" ;; # Requiere 'unrar'
    *.gz) gunzip "$1" ;;
    *.tar) tar xf "$1" ;;
    *.tbz2) tar xjf "$1" ;;
    *.tgz) tar xzf "$1" ;;
    *.zip) unzip "$1" ;;
    *.Z) uncompress "$1" ;;
    *.7z) 7z x "$1" ;; # Requiere '7zip'
    *) echo "No se puede extraer '$1': formato no reconocido o herramienta no instalada." ;;
  esac
}

killport(){
  [ $# -eq 0 ] && echo "Uso: killport <puerto>" && return 1
  local pid=$(lsof -ti:"$1" 2>/dev/null) # Requiere 'lsof'
  [ -n "$pid" ] && kill -9 "$pid" && echo "✅ Proceso en puerto $1 eliminado (PID: $pid)" || echo "🤷 No se encontró ningún proceso en el puerto $1"
}

serve(){ python -m http.server "${1:-8000}"; }

# --- yt-dlp MEJORADO ---------------------------------------------------------
# Requiere yt-dlp instalado
export YTDLP_DIR="$HOME/Videos/YouTube"
mkdir -p "$YTDLP_DIR"/{Music,Videos} 2>/dev/null # Crear directorios si no existen

ytm() {
  case "$1" in
    -h|--help|'')
      echo "🎵 ytm <URL|búsqueda> - Descarga audio (MP3 320kbps) a $YTDLP_DIR/Music/"
      echo "Ejemplos:"
      echo "  ytm https://youtu.be/dQw4w9WgXcQ"
      echo "  ytm 'Never Gonna Give You Up'"
      return 0
      ;;
  esac

  if ! command -v yt-dlp &>/dev/null; then
    echo "❌ yt-dlp no está instalado. Por favor, instálalo para usar esta función."
    return 1
  fi
  
  local out="$YTDLP_DIR/Music/%(title).180s.%(ext)s"
  local opts=(
    --extract-audio --audio-format mp3 --audio-quality 320K
    --embed-metadata --embed-thumbnail --convert-thumbnails jpg
    --no-playlist --retries 10 --fragment-retries 10
    --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
    --extractor-args "youtube:player_client=android,web"
    --progress --newline -o "$out"
  )
  
  if [[ "$1" == http* ]]; then
    echo "📥 Descargando audio..."
    yt-dlp "${opts[@]}" "$@"
  else
    echo "🔍 Buscando: $*"
    yt-dlp "${opts[@]}" "ytsearch1:$*"
  fi
  
  [ $? -eq 0 ] && echo "✅ Audio descargado en: $YTDLP_DIR/Music/" || echo "❌ Falló la descarga de audio."
}

ytv() {
  case "$1" in
    -h|--help|'')
      echo "🎬 ytv <URL|búsqueda> [calidad] - Descarga video a $YTDLP_DIR/Videos/"
      echo "Calidades disponibles: 1080, 720, 480 (por defecto: mejor disponible MP4)"
      echo "Ejemplos:"
      echo "  ytv https://youtu.be/dQw4w9WgXcQ 1080"
      echo "  ytv 'Rick Astley - Never Gonna Give You Up' 720"
      return 0
      ;;
  esac

  if ! command -v yt-dlp &>/dev/null; then
    echo "❌ yt-dlp no está instalado. Por favor, instálalo para usar esta función."
    return 1
  fi
  
  local quality="${2:-best}"
  local out="$YTDLP_DIR/Videos/%(title).180s.%(ext)s"
  
  local fmt
  case "$quality" in
    1080) fmt='bv*[height<=1080][ext=mp4]+ba/b[height<=1080]' ;;
    720)  fmt='bv*[height<=720][ext=mp4]+ba/b[height<=720]' ;;
    480)  fmt='bv*[height<=480][ext=mp4]+ba/b[height<=480]' ;;
    *)    fmt='bv*[ext=mp4]+ba/b[ext=mp4]/b' ;; # Mejor calidad MP4
  esac
  
  local opts=(
    -f "$fmt" --embed-metadata --embed-thumbnail
    --embed-subs --sub-langs "es.*,en.*" --convert-thumbnails jpg
    --no-playlist --retries 10 --fragment-retries 10
    --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
    --extractor-args "youtube:player_client=android,web"
    --progress --newline -o "$out"
  )
  
  if [[ "$1" == http* ]]; then
    echo "📥 Descargando video..."
    yt-dlp "${opts[@]}" "$1"
  else
    echo "🔍 Buscando: $1"
    yt-dlp "${opts[@]}" "ytsearch1:$1"
  fi
  
  [ $? -eq 0 ] && echo "✅ Video descargado en: $YTDLP_DIR/Videos/" || echo "❌ Falló la descarga de video."
}

ytls() {
  echo "🎵 Últimos 5 audios descargados en Music:"
  ls -1t "$YTDLP_DIR/Music" 2>/dev/null | head -5 | sed 's/^/  /' || echo "  (vacío)"
  echo ""
  echo "🎬 Últimos 5 videos descargados en Videos:"
  ls -1t "$YTDLP_DIR/Videos" 2>/dev/null | head -5 | sed 's/^/  /' || echo "  (vacío)"
}

# --- GNOME Keyring -----------------------------------------------------------
# Iniciar gnome-keyring-daemon si la sesión es gráfica y no está corriendo
if [ -n "$DESKTOP_SESSION" ]; then
  if ! pgrep -u "$USER" gnome-keyring-daemon > /dev/null 2>&1; then
    eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh 2>/dev/null)
  fi
  export SSH_AUTH_SOCK GPG_AGENT_INFO GNOME_KEYRING_CONTROL GNOME_KEYRING_PID
fi

# --- SSH Agent ---------------------------------------------------------------
# Iniciar ssh-agent si no está corriendo y manejar las llaves SSH
if [ -z "$SSH_AUTH_SOCK" ]; then
  export SSH_AGENT_DIR="$HOME/.ssh/agent"
  mkdir -p "$SSH_AGENT_DIR"
  SSH_ENV="$SSH_AGENT_DIR/env"
  
  start_agent() {
    echo "🔑 Iniciando ssh-agent..."
    ssh-agent > "$SSH_ENV"
    chmod 600 "$SSH_ENV"
    . "$SSH_ENV" > /dev/null
  }
  
  if [ -f "$SSH_ENV" ]; then
    . "$SSH_ENV" > /dev/null
    ps -p $SSH_AGENT_PID > /dev/null 2>&1 || start_agent
  else
    start_agent
  fi
  
  if [ -d "$HOME/.ssh" ]; then
    for key in "$HOME/.ssh"/*; do
      if [ -f "$key" ] && [[ ! "$key" =~ \.pub$ ]] && \
         [[ ! "$key" =~ known_hosts ]] && [[ ! "$key" =~ authorized_keys ]] && \
         [[ ! "$key" =~ config ]] && [[ ! "$key" =~ agent ]]; then
        if ssh-keygen -l -f "$key" &>/dev/null; then
          local key_fingerprint=$(ssh-keygen -lf "$key" 2>/dev/null | awk '{print $2}')
          if ! ssh-add -l 2>/dev/null | grep -q "$key_fingerprint"; then
            if ssh-add "$key" 2>/dev/null; then
              echo "✅ Llave SSH agregada: $(basename $key)"
            fi
          fi
        fi
      fi
    done
  fi
fi

# Alias útiles para SSH
alias ssh-list='ssh-add -l'                    # Listar llaves cargadas
alias ssh-clear='ssh-add -D'                   # Limpiar todas las llaves
alias ssh-reload='                             # Recargar todas las llaves
  ssh-add -D 2>/dev/null
  for key in ~/.ssh/*; do
    if [ -f "$key" ] && [[ ! "$key" =~ \.pub$ ]] && ssh-keygen -l -f "$key" &>/dev/null; then
      ssh-add "$key" 2>/dev/null && echo "✅ $(basename $key)"
    fi
  done
'

alias ssh-github='ssh -T git@github.com'       # Test GitHub connection

# --- zoxide ------------------------------------------------------------------
# Reemplazo inteligente de cd (requiere zoxide)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
  
  # Alias para compatibilidad con el comportamiento tradicional
  alias cd='z'
  alias cdi='zi'                               # Interactive mode
  alias zz='z -'                               # Ir al directorio anterior
else
  echo "Advertencia: zoxide no está instalado. Instálalo para usar 'z', 'zi', 'zz'."
fi


# --- Historial de Zsh --------------------------------------------------------
HISTSIZE=100000        # Número de comandos guardados en el historial en RAM
SAVEHIST=100000        # Número de comandos guardados en el archivo de historial
HISTFILE=~/.zsh_history # Archivo donde se guarda el historial
setopt APPEND_HISTORY   # Añadir nuevos comandos al archivo de historial
setopt SHARE_HISTORY    # Compartir historial entre sesiones de Zsh
setopt HIST_IGNORE_DUPS # No guardar comandos duplicados consecutivamente
setopt HIST_IGNORE_ALL_DUPS # No guardar comandos duplicados en el historial
setopt HIST_IGNORE_SPACE    # No guardar comandos que comienzan con espacio
setopt AUTO_CD          # Si se introduce un directorio, cambiar a él
setopt EXTENDED_GLOB    # Habilitar características de expansión de comodines extendidas

stty -ixon 2>/dev/null # Deshabilita CTRL+S (pause) y CTRL+Q (resume)

export LESS='-R' # Habilita colores en man pages y less

# --- Funciones externas ------------------------------------------------------
# Cargar cualquier archivo .zsh que se encuentre en ~/.zsh_functions/
[ -d "$HOME/.zsh_functions" ] || mkdir -p "$HOME/.zsh_functions"
for func_file in "$HOME/.zsh_functions"/*.zsh(N); do
  source "$func_file"
done

# --- Local Overrides ---------------------------------------------------------
# Permite tener un archivo ~/.zshrc.local para configuraciones personales
# sin modificar el archivo principal. Este archivo se cargará al final.
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# Mensaje de bienvenida (opcional, puedes borrarlo)
#echo "🌈 Zsh está configurado con Catppuccin Frappe. ¡Disfruta!"
