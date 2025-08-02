#!/usr/bin/env bash
set -euo pipefail

# Variables
REPO_URL="https://github.com/Lekensteyn/ltunify.git"
WORKDIR="$HOME/ltunify"
BIN_HOME="$HOME/bin"
UDEV_RULES="/etc/udev/rules.d/50-ltunify.rules"
PROFILE="$HOME/.profile"
GROUP="plugdev"

# 1. Instala dependencias
echo "Instalando dependencias..."
sudo apt update
sudo apt install -y git build-essential libhidapi-dev

# 2. Clona o actualiza el repositorio
if [[ -d "$WORKDIR" ]]; then
  echo "Actualizando ltunify en $WORKDIR..."
  git -C "$WORKDIR" pull
else
  echo "Clonando ltunify en $WORKDIR..."
  git clone "$REPO_URL" "$WORKDIR"
fi

# 3. Compila
echo "Compilando ltunify..."
cd "$WORKDIR"
make ltunify

# 4. Instalación del binario en ~/bin
echo "Instalando binario en $BIN_HOME..."
mkdir -p "$BIN_HOME"
make install-home

# 5. Asegura que ~/bin esté en el PATH
if ! grep -qxF 'export PATH="$HOME/bin:$PATH"' "$PROFILE"; then
  echo 'export PATH="$HOME/bin:$PATH"' >> "$PROFILE"
  echo "Añadida línea a $PROFILE para incluir ~/bin en PATH."
fi

# 6. Crea grupo plugdev si no existe y añade al usuario
if ! getent group "$GROUP" >/dev/null; then
  echo "Creando grupo $GROUP..."
  sudo groupadd "$GROUP"
fi

echo "Añadiendo usuario $USER al grupo $GROUP..."
sudo usermod -aG "$GROUP" "$USER"

# 7. Instala reglas udev
echo "Escribiendo reglas udev en $UDEV_RULES..."
sudo tee "$UDEV_RULES" >/dev/null <<EOF
# Logitech Unifying Receiver
KERNEL=="hidraw[0-9]*", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c52b", MODE="0664", GROUP="$GROUP"
EOF

# 8. Recarga reglas udev
echo "Recargando reglas udev..."
sudo udevadm control --reload-rules
sudo udevadm trigger

# 9. Final
echo
echo "¡Listo! Cierra y vuelve a abrir tu terminal (o ejecuta 'newgrp $GROUP') para aplicar los cambios."
echo "Luego prueba:"
echo "  ltunify list"
echo "  ltunify pair"
echo "  ltunify info 0"
echo "  ltunify unpair 0"

exit 0
