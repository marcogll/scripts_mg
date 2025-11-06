#!/usr/bin/env bash
#───────────────────────────────────────────────────────────────
# 🌀 Omarchy Setup Script — Configuración base para Arch Linux
#───────────────────────────────────────────────────────────────
# Este script prepara un entorno listo para usar con Zsh, Docker,
# Portainer, VS Code, Cursor, VLC (por defecto en multimedia),
# y descarga scripts y configuraciones personalizados desde
# tu repositorio oficial de GitHub.
#───────────────────────────────────────────────────────────────

set -e  # Detiene el script si algo falla
REPO_BASE="https://raw.githubusercontent.com/marcogll/scripts_mg/refs/heads/main/omarchy_zsh_setup"

#───────────────────────────────────────────────────────────────
# 🌐 Actualización del sistema
#───────────────────────────────────────────────────────────────
echo "→ Actualizando el sistema..."
sudo pacman -Syu --noconfirm

#───────────────────────────────────────────────────────────────
# ⚙️ Instalación de herramientas base y dependencias
#───────────────────────────────────────────────────────────────
echo "→ Instalando paquetes base..."
sudo pacman -S --noconfirm --needed \
    git curl wget base-devel unzip zsh zsh-completions zsh-syntax-highlighting \
    zsh-autosuggestions neofetch htop fastfetch btop vim nano tmux \
    docker docker-compose portainer \
    code vlc vlc-plugin libdvdcss ffmpeg gstreamer gst-plugins-good gst-plugins-bad gst-plugins-ugly \
    xdg-utils xdg-user-dirs

#───────────────────────────────────────────────────────────────
# ⚙️ Configuración de Docker y Portainer
#───────────────────────────────────────────────────────────────
echo "→ Configurando Docker y Portainer..."
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
sudo systemctl start docker.service
sudo docker volume create portainer_data
sudo docker run -d -p 8000:8000 -p 9443:9443 \
    --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest

#───────────────────────────────────────────────────────────────
# 🧠 Instalación de AUR packages (Cursor, Intel OpenCL)
#───────────────────────────────────────────────────────────────
echo "→ Verificando helper AUR (yay o paru)..."
if command -v yay >/dev/null 2>&1; then
    echo "→ Instalando paquetes AUR con yay..."
    yay -S --noconfirm intel-opencl-clang-git cursor-bin
elif command -v paru >/dev/null 2>&1; then
    echo "→ Instalando paquetes AUR con paru..."
    paru -S --noconfirm intel-opencl-clang-git cursor-bin
else
    echo "⚠️ No se detectó yay ni paru. Instalando yay..."
    cd /tmp
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    yay -S --noconfirm intel-opencl-clang-git cursor-bin
fi

#───────────────────────────────────────────────────────────────
# 🧰 Descarga de configuraciones personalizadas desde GitHub
#───────────────────────────────────────────────────────────────
echo "→ Descargando configuración de Zsh y scripts..."
cd ~
curl -fsSL "$REPO_BASE/.zshrc" -o ~/.zshrc
curl -fsSL "$REPO_BASE/omarchy-setup.sh" -o ~/omarchy-setup.sh
curl -fsSL "$REPO_BASE/davince_resolve_intel.sh" -o ~/davince_resolve_intel.sh
chmod +x ~/omarchy-setup.sh ~/davince_resolve_intel.sh

#───────────────────────────────────────────────────────────────
# 🧩 Configuración de Zsh como shell por defecto
#───────────────────────────────────────────────────────────────
if [ "$SHELL" != "/bin/zsh" ]; then
    echo "→ Configurando Zsh como shell predeterminada..."
    chsh -s /bin/zsh
fi

#───────────────────────────────────────────────────────────────
# 🎧 Configuración de VLC como reproductor multimedia predeterminado
#───────────────────────────────────────────────────────────────
echo "→ Configurando VLC como reproductor predeterminado..."
xdg-mime default vlc.desktop audio/mpeg
xdg-mime default vlc.desktop audio/mp4
xdg-mime default vlc.desktop audio/x-wav
xdg-mime default vlc.desktop video/mp4
xdg-mime default vlc.desktop video/x-matroska
xdg-mime default vlc.desktop video/x-msvideo
xdg-mime default vlc.desktop video/x-ms-wmv
xdg-mime default vlc.desktop video/webm

#───────────────────────────────────────────────────────────────
# 🧼 Limpieza final
#───────────────────────────────────────────────────────────────
echo "→ Limpiando paquetes huérfanos..."
sudo pacman -Rns $(pacman -Qtdq) --noconfirm || true

#───────────────────────────────────────────────────────────────
# ✅ Finalización
#───────────────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────"
echo "✅ Instalación de entorno Omarchy completada"
echo "────────────────────────────────────────────"
echo "Zsh configurado, Docker y Portainer listos,"
echo "VLC por defecto en multimedia, VS Code y Cursor instalados."
echo ""
echo "Siguiente paso: ejecutar tu script de DaVinci Resolve si corresponde."
echo "Ubicación: ~/davince_resolve_intel.sh"
echo ""
