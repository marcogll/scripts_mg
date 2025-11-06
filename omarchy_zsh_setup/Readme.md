# 🚀 Omarchy System Setup v2.9

Script de instalación y configuración completa para **Omarchy Linux** (Arch/Hyprland Edition).
Diseñado para dejar el sistema completamente listo antes de instalar DaVinci Resolve u otros programas pesados.
Esta versión automatiza la configuración de entorno, fuentes, temas, herramientas y drivers esenciales.

---

## ⚡ Instalación rápida

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/marcogll/scripts_mg/refs/heads/main/omarchy_zsh_setup/omarchy-setup.sh)

```

---

## 🧩 Qué hace este script

### 1. 🐚 Configuración del entorno de shell

* Instala **Zsh** y lo define como shell predeterminado.
* Instala **Oh My Zsh** y los plugins:

  * `zsh-autosuggestions`
  * `zsh-syntax-highlighting`
  * `colorize`
* Instala **Oh My Posh** y aplica el tema Catppuccin.
* Instala la fuente **Meslo Nerd Font** (`oh-my-posh font install meslo`).

### 2. 🧠 Integración de Bash y Zsh

* Configura `.bashrc` para:

  * Lanzar Zsh automáticamente.
  * Cargar las variables de entorno de Homebrew (`eval $(brew shellenv)`).
  * Mantener limpio el entorno de login sin duplicar configuraciones.

### 3. 🍺 Homebrew Linux

* Instala **Homebrew** (Linuxbrew) para manejar paquetes adicionales.
* Agrega su entorno al perfil del usuario.

### 4. 📦 Paquetes base (pacman)

Instala herramientas esenciales del sistema:

* `git`, `curl`, `wget`, `base-devel`, `nano`, `gedit`, `fastfetch`, `htop`, `eza`, `zoxide`, `bat`, `tree`, `docker`, `docker-compose`, `gnome-keyring`, `ssh`, `python`, `nodejs`, `npm`, `go`, `nvm`, `yt-dlp`, `unzip`, `zip`, `unrar`, `p7zip`.

### 5. 💻 Aplicaciones de escritorio

Instala los siguientes programas desde **pacman**:

* **VS Code**
* **Cursor**
* **FileZilla**
* **Telegram Desktop**
* **Gedit**
* **Nano**

### 6. 📦 Flatpak (opcional)

* Instala **Flatpak** y agrega los repositorios base.
* No instala apps, solo deja el entorno preparado para usarlo.

### 7. 🎨 Drivers gráficos Intel Iris Xe

Instala soporte multimedia completo para **DaVinci Resolve** y otras apps:

* `intel-media-driver`
* `intel-compute-runtime`
* `libva-intel-driver`
* `vulkan-intel`
* `intel-opencl` (soporte OpenCL completo)
* `gstreamer` + plugins (base, good, bad, ugly, libav)

### 8. 🖨️ Drivers Epson L4150 y Epson Scan2

Instala controladores para impresión y escaneo:

* `epson-inkjet-printer-escpr`
* `epsonscan2` (si está disponible en repos o AUR)

### 9. 🧭 Logitech Tools

Instala utilidades para dispositivos Logitech:

* `ltunify`
* `logiops`

### 10. 🎨 Estética y personalización

* Aplica **tema Catppuccin** al entorno.
* Configura mensajes visuales de progreso con colores suaves.
* Muestra banner de bienvenida al iniciar el script.

---

## 📂 Estructura del entorno resultante

```
~/.zshrc         → Configuración principal (Omarchy v2.1 o superior)
~/.bashrc        → Lanzador automático de Zsh + Homebrew env
~/.local/share/omarchy/  → Configuración de temas y funciones personalizadas
```

---

## 💡 Uso posterior

Una vez ejecutado este script:

1. Copia tu `.zshrc` personalizado de Omarchy (v2.1 o superior).
2. Ejecuta `zsh` y confirma que todo carga correctamente (Oh My Posh, plugins, etc.).
3. El sistema quedará listo para instalar **DaVinci Resolve** con el script dedicado (`davinci_resolve_intel.sh`).

---

## 🧾 Licencia

Este proyecto se distribuye bajo la licencia MIT.
© 2025 Marco GLL — Proyecto Omarchy.
