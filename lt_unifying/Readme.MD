# Instalación de ltunify en Ubuntu

Esta guía describe cómo instalar **ltunify**, la herramienta para gestionar receptores y dispositivos Logitech Unifying en Ubuntu. ltunify permite emparejar y desemparejar dispositivos Unifying de forma nativa en Linux.

Para más detalles, consulta el repositorio oficial:
- https://github.com/Lekensteyn/ltunify#readme [1]

---

## Opción 1: Desde repositorios oficiales (Recomendado)

La forma más sencilla y segura es mediante `apt`, usando la versión mantenida por Ubuntu:

```bash
# 1. Actualiza la lista de paquetes
sudo apt update

# 2. Instala ltunify
sudo apt install ltunify
````

**Ventajas**:

* Paquete verificado y actualizado automáticamente junto al sistema.
* No requiere compilación manual ni configuración extra.

---

## Opción 2: Instalación manual con script (Avanzado)

Este método descarga, compila y configura ltunify desde su código fuente. Procede con precaución, ya que implica ejecutar un script remoto.

### Requisitos previos

* Ubuntu 18.04 o superior
* Usuario con permisos `sudo`
* Conexión a Internet
* El script instalará: `git`, `build-essential`, `libhidapi-dev`

### A. One‑liner con curl

```bash
curl -fsSL https://raw.githubusercontent.com/marcogll/scripts_mg/main/lt_unifying/install-ltunify.sh | bash
```

**Qué hace**:

1. Descarga el instalador.
2. Ejecuta el script en Bash.
3. Solicita `sudo` al instalar dependencias y configurar udev.

### B. Descargar y luego ejecutar

```bash
# 1) Descarga el script
curl -fsSL -o install-ltunify.sh \
  https://raw.githubusercontent.com/marcogll/scripts_mg/main/lt_unifying/install-ltunify.sh

# 2) Permisos de ejecución
chmod +x install-ltunify.sh

# 3) Ejecutarlo
./install-ltunify.sh
```

**Qué hace**:

* Guarda el instalador localmente para revisión previa antes de ejecutar.

### C. One‑liner con wget

```bash
wget -qO- https://raw.githubusercontent.com/marcogll/scripts_mg/main/lt_unifying/install-ltunify.sh | bash
```

**Qué hace**:

* Igual que la opción con `curl`, usando `wget`.

---

## Pasos internos del script [2]

1. Instala dependencias: `git`, `build-essential`, `libhidapi-dev`.
2. Clona o actualiza [https://github.com/Lekensteyn/ltunify](https://github.com/Lekensteyn/ltunify).
3. Compila el binario `ltunify`.
4. Instala en `~/bin` y ajusta `PATH` (o globalmente en `/usr/local/bin`).
5. Crea el grupo `plugdev` y añade tu usuario.
6. Instala reglas udev para `/dev/hidraw*` (MODE="0664", GROUP="plugdev").
7. Recarga las reglas udev sin reiniciar.

---

## Después de la instalación

* Cierra y vuelve a abrir la terminal (o ejecuta `newgrp plugdev`).
* Prueba los comandos:

  ```bash
  ltunify list     # Lista dispositivos Unifying  
  ltunify pair     # Empareja un dispositivo (modo 60s)  
  ltunify info 0   # Muestra detalles del primer dispositivo  
  ltunify unpair 0 # Desempareja el primer dispositivo
  ```

---

> **Seguridad**: Revisa siempre el contenido de scripts remotos antes de ejecutarlos. Ejecuta como usuario normal; el script solicitará privilegios únicamente cuando sea necesario.

---

[1]: https://github.com/Lekensteyn/ltunify#readme
[2]: https://raw.githubusercontent.com/marcogll/scripts_mg/main/lt_unifying/install-ltunify.sh

```
```
