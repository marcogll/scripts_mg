# ================================================================
# Omarchy Zsh Configuration v2.5 (Omarchy-MG Edition)
# ================================================================

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"

# Plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)

source $ZSH/oh-my-zsh.sh

# ----------------------------
# Aliases y herramientas base
# ----------------------------
alias ll='eza -lh --icons'
alias la='eza -lha --icons'
alias gs='git status'
alias v='nvim'
alias cat='bat'
alias cls='clear'

# ----------------------------
# FZF y Zoxide (si existen)
# ----------------------------
if command -v fzf &>/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# ----------------------------
# Oh My Posh Prompt
# ----------------------------
if command -v oh-my-posh &>/dev/null; then
  eval "$(oh-my-posh init zsh --config ~/.poshthemes/omarchy.omp.json)"
fi

# ----------------------------
# PATH
# ----------------------------
export PATH="$HOME/.local/bin:$PATH"

# ================================================================
# >>> Omarchy MG v2.5 additions >>>
# ================================================================

# --- Homebrew (Linuxbrew) integration ---
if [ -d /home/linuxbrew/.linuxbrew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -d "$HOME/.linuxbrew" ]; then
    eval "$($HOME/.linuxbrew/bin/brew shellenv)"
fi

# --- Docker group check ---
if command -v docker &>/dev/null; then
  if ! groups $USER | grep -q '\bdocker\b'; then
    echo "⚠️  Nota: el usuario $USER no pertenece al grupo docker."
    echo "   Ejecute: sudo usermod -aG docker $USER && newgrp docker"
  fi
fi

# --- TeamViewer control helpers ---
alias teamviewerd-start="sudo systemctl start teamviewerd.service"
alias teamviewerd-enable="sudo systemctl enable teamviewerd.service"

# --- Creative tools quick launch ---
alias aud="audacity &>/dev/null & disown"
alias inks="inkscape &>/dev/null & disown"

# --- Info banner ---
# echo -e "\n${ZSH_THEME:+🎨 }Bienvenido a Omarchy Zsh v2.5 (MG Edition)"
echo "Sistema: $(uname -a | cut -d ' ' -f1-3)"
echo "Shell: $(zsh --version)"
echo "Usuario: $USER"
echo "--------------------------------------"

# ================================================================
# >>> End of Omarchy MG v2.5 additions <<<
# ================================================================
