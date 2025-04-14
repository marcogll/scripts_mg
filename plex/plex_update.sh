#!/bin/bash
# Script para actualizar Plex Media Server automáticamente
echo "=== Iniciando actualización de Plex Media Server ==="

# URL de descarga
DOWNLOAD_URL="https://plex.tv/downloads/latest/5?channel=16&build=linux-x86_64&distro=debian&X-Plex-Token=xxxxxxxxxxxxxxxxxxxx"
DEB_FILE="plexmediaserver_latest.deb"

# Descargar el archivo
echo "Descargando la última versión de Plex..."
wget "$DOWNLOAD_URL" -O "$DEB_FILE"
if [ $? -ne 0 ]; then
    echo "Error: La descarga ha fallado."
    exit 1
fi

# Obtener información del paquete descargado
echo "Obteniendo información de la versión..."
VERSION=$(dpkg -I "$DEB_FILE" | grep -i version | head -1 | awk '{print $2}')
echo "Versión descargada: $VERSION"

# Instalar el paquete
echo "Instalando Plex Media Server..."
dpkg -i "$DEB_FILE"

# Verificar si hay dependencias faltantes y resolverlas
if [ $? -ne 0 ]; then
    echo "Resolviendo dependencias..."
    apt-get update
    apt-get -f install -y
fi

# Eliminar el archivo .deb
echo "Limpiando archivos temporales..."
rm -f "$DEB_FILE"

# Como estamos en Docker, notificar al usuario sobre el reinicio
echo "=== Actualización completada ==="
echo "Plex Media Server ha sido actualizado a la versión $VERSION"
echo "NOTA: Como estás en un contenedor Docker, puede que necesites reiniciar el contenedor"
echo "para que los cambios surtan efecto. Esto se puede hacer desde la interfaz de TrueNAS SCALE."
