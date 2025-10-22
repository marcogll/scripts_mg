# 🚀 Omarchy Zsh Setup Script

Script de instalación y configuración completa para **Omarchy Linux** con Zsh, Oh My Posh, y todas las herramientas esenciales.

## ⚡ Instalación rápida

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/marcogll/scripts_mg/main/omarchy_zsh_setup/omarchy-setup.sh)
```

---

## ✨ Características

### 🎨 Terminal y Shell
- **Zsh** + **Oh My Zsh** + plugins (autosuggestions, syntax-highlighting)
- **Oh My Posh** con tema Catppuccin
- Aliases útiles para Arch, Git, Docker, NPM, Python

### 🌐 Navegador
- Instala **Google Chrome** desde AUR
- Remueve **omarchy-chromium** automáticamente

### 🖨️ Impresora
- Drivers oficiales **Epson L4150** (ESC/P-R)
- CUPS configurado y listo para conectar
- Acceso web: `http://localhost:631`

### 🔐 Seguridad y Red
- **ZeroTier One** con conexión interactiva
- **GNOME Keyring** configurado (para Git, VS Code)
- Opciones: sin contraseña, contraseña de usuario, o personalizada

### 😊 Utilidades
- **Emoji Launcher** (rofimoji) - Presiona `SUPER + .`
- **yt-dlp** para descargar audio/video de YouTube
- Thumbnails en Nautilus para imágenes/videos/PDFs

### 🛠️ Desarrollo
- Git, Docker, Docker Compose
- Node.js, NPM (global en `~/.npm-global`)
- Python, pip, virtualenv
- Soporte para NVM

---

## 📦 Paquetes instalados

<details>
<summary>Ver lista completa (click para expandir)</summary>

### Sistema Base
- zsh, oh-my-zsh, oh-my-posh
- git, curl, wget
- yay (AUR helper)

### Desarrollo
- python, python-pip, python-virtualenv
- nodejs, npm
- docker, docker-compose

### Multimedia
- yt-dlp, ffmpeg
- tumbler, ffmpegthumbnailer
- gst-plugins-{good,bad,ugly}
- libheif, webp-pixbuf-loader

### Utilidades
- playerctl, brightnessctl, pamixer
- neofetch, htop, btop
- tree, unzip, p7zip, unrar
- rofi, wl-clipboard, rofimoji

### Red y Seguridad
- zerotier-one
- gnome-keyring, libsecret, seahorse
- lsof, net-tools

### Impresión
- cups, cups-pdf
- system-config-printer
- gutenprint
- epson-inkjet-printer-escpr{,2}

</details>

---

## 🎯 Durante la instalación

El script te preguntará:

1. **¿Continuar con la instalación?** (Y/n)
2. **ZeroTier Network ID** - Tu red privada (opcional)
3. **GNOME Keyring:**
   - Sin contraseña (más conveniente)
   - Igual a tu contraseña de usuario (recomendado)
   - Contraseña personalizada
4. **Configuración de Git** - Nombre y email (opcional)

---

## 🔑 GNOME Keyring

El keyring guarda contraseñas de:
- Git (credential helper)
- VS Code
- SSH keys
- Aplicaciones GNOME

### Opciones recomendadas:

| Opción | Seguridad | Conveniencia | Recomendado para |
|--------|-----------|--------------|------------------|
| Sin contraseña | Baja | Alta | Laptop personal |
| Contraseña de usuario | Alta | Alta | Uso general ⭐ |
| Contraseña personalizada | Alta | Media | Datos sensibles |

### Configuración post-instalación:

```bash
# Abrir gestor de contraseñas
seahorse

# Ver estado del keyring
gnome-keyring-daemon --version

# Comandos de ZeroTier
zt              # Alias de zerotier-cli
ztstatus        # Ver redes conectadas
ztinfo          # Info del nodo
```

---

## ⚙️ Configuración incluida

### Aliases de Arch Linux
```bash
pacu            # Actualizar sistema
paci <pkg>      # Instalar paquete
pacr <pkg>      # Remover paquete
pacs <query>    # Buscar paquete
yayu            # Actualizar AUR
yayi <pkg>      # Instalar desde AUR
```

### Git shortcuts
```bash
gs              # git status
ga              # git add
gc              # git commit
gcm "msg"       # git commit -m
gp              # git push
gl              # git pull
gco <branch>    # git checkout
gcb <branch>    # git checkout -b
glog            # git log gráfico
gac "msg"       # add + commit
```

### Docker
```bash
dc              # docker compose
d               # docker
dps             # docker ps -a
di              # docker images
dex <name> sh   # docker exec -it
dlog <name>     # docker logs -f
```

### Python
```bash
py              # python
venv create     # Crear .venv
venv on         # Activar
venv off        # Desactivar
pir             # pip install -r requirements.txt
pipf            # pip freeze > requirements.txt
```

### yt-dlp
```bash
ytm <URL>           # Descargar audio MP3 320kbps
ytm "lofi beats"    # Buscar y descargar
ytv <URL>           # Descargar video MP4
ytv "tutorial"      # Buscar y descargar video
```

Descargas en: `~/Videos/ytdlp/`

### NPM
```bash
nrs             # npm run start
nrd             # npm run dev
nrb             # npm run build
nrt             # npm run test
ni              # npm install
nid             # npm install --save-dev
nig             # npm install -g
```

### Utilidades
```bash
mkcd <dir>          # mkdir + cd
extract <file>      # Extraer cualquier archivo
killport <port>     # Matar proceso en puerto
serve [port]        # Servidor HTTP (default 8000)
clima               # Ver clima Saltillo
```

---

## 🎨 Emoji Launcher

Presiona **SUPER + .** (tecla Windows + punto) para abrir el selector de emojis.

- Busca por nombre: "heart", "smile", "rocket"
- Navega con flechas
- Enter para copiar al portapapeles
- Compatible con Wayland/Hyprland

---

## 🖨️ Configurar Impresora Epson L4150

### Opción 1: Interfaz web (recomendado)

```bash
# Abrir en navegador
http://localhost:631

# Ir a: Administration → Add Printer
# Buscar: Epson L4150
# Seleccionar driver: Epson L4150 Series
```

### Opción 2: Herramienta gráfica

```bash
system-config-printer
```

### Conexión:
- **USB**: Detecta automáticamente
- **WiFi**: Buscar impresoras de red
- **IP**: Usar dirección IP de la impresora

---

## 🌐 ZeroTier Network ID

Tu Network ID tiene formato: `a0cbf4b62a1234567` (16 caracteres hex)

### Dónde encontrarlo:
1. Ve a https://my.zerotier.com
2. Selecciona tu red
3. Copia el Network ID

### Después de la instalación:
1. Ve a tu panel de ZeroTier
2. Busca el nuevo dispositivo
3. **Autorízalo** marcando el checkbox

### Comandos útiles:
```bash
# Ver redes
ztstatus

# Unirse a red
sudo zerotier-cli join <network-id>

# Salir de red
sudo zerotier-cli leave <network-id>

# Info del nodo
ztinfo
```

---

## 📂 Estructura creada

```
$HOME/
├── .zshrc                          # Configuración de Zsh
├── .zshrc.local                   # Config local (opcional)
├── .oh-my-zsh/                    # Oh My Zsh
│   └── custom/plugins/            # Plugins adicionales
├── .poshthemes/                   # Temas Oh My Posh
│   └── catppuccin.omp.json
├── .npm-global/                   # NPM global packages
├── .zsh_functions/                # Funciones personalizadas
├── AppImages/                     # Aplicaciones AppImage
├── Videos/ytdlp/                  # Descargas de yt-dlp
└── Projects/                      # Tus proyectos
```

---

## 🔄 Después de la instalación

### 1. Reiniciar sesión (IMPORTANTE)

```bash
# Cerrar sesión y volver a entrar
# Esto aplica:
# - Cambio de shell a Zsh
# - Grupos (docker, video, lp)
# - Permisos de brillo
```

### 2. Verificar instalación

```bash
# Ver versión de Zsh
zsh --version

# Ver tema
oh-my-posh version

# Ver ZeroTier
ztstatus

# Actualizar sistema
pacu
```

### 3. Configuraciones opcionales

```bash
# Crear archivo de configuración local
nano ~/.zshrc.local

# Ejemplo de contenido:
export OPENAI_API_KEY="sk-..."
export GITHUB_TOKEN="ghp_..."
alias miproyecto="cd ~/Projects/mi-app && code ."
```

---

## 🛠️ Solución de problemas

### Las teclas Fn de brillo no funcionan

```bash
# Verificar permisos
groups  # Debe incluir 'video'

# Reiniciar sesión si no aparece
```

### Git sigue pidiendo contraseña

```bash
# Verificar credential helper
git config --global credential.helper

# Debe ser: libsecret

# Si no, configurar:
git config --global credential.helper libsecret

# Abrir Seahorse y verificar keyring
seahorse
```

### ZeroTier no conecta

```bash
# Ver logs
sudo journalctl -u zerotier-one -f

# Reiniciar servicio
sudo systemctl restart zerotier-one

# Verificar que autorizaste en https://my.zerotier.com
```

### Emoji launcher no abre

```bash
# Verificar instalación
which rofimoji

# Recargar Hyprland
hyprctl reload

# Probar desde terminal
rofimoji
```

### Impresora no detectada

```bash
# Verificar servicio CUPS
sudo systemctl status cups

# Reiniciar CUPS
sudo systemctl restart cups

# Ver impresoras detectadas
lpstat -p -d
```

---

## 📚 Recursos

- **Arch Wiki**: https://wiki.archlinux.org/
- **Oh My Zsh**: https://ohmyz.sh/
- **Oh My Posh**: https://ohmyposh.dev/
- **ZeroTier**: https://www.zerotier.com/
- **yt-dlp**: https://github.com/yt-dlp/yt-dlp
- **Epson Drivers**: https://aur.archlinux.org/packages/epson-inkjet-printer-escpr

---

## 🆘 Soporte

Si encuentras problemas:

1. Revisa los logs del script durante la instalación
2. Verifica que cerraste sesión después de instalar
3. Comprueba que los grupos se aplicaron: `groups`
4. Abre un issue en: https://github.com/marcogll/scripts_mg/issues

---

## 📝 Changelog

### v1.0.0 (2025-01-21)
- Instalación inicial de Zsh + Oh My Posh
- Google Chrome reemplaza omarchy-chromium
- Drivers Epson L4150
- ZeroTier One con configuración interactiva
- GNOME Keyring con opciones de contraseña
- Emoji Launcher (rofimoji)
- Thumbnails en Nautilus
- Aliases y funciones útiles

---

## 📄 Licencia

MIT License - Libre de usar y modificar

---

## 👤 Autor

**Marco**
- GitHub: [@marcogll](https://github.com/marcogll)
- Repo: [scripts_mg](https://github.com/marcogll/scripts_mg)

---

## ⭐ ¿Te gustó?

Si este script te fue útil, dale una estrella ⭐ al repo!

```bash
# Instalar en una línea
bash <(curl -fsSL https://raw.githubusercontent.com/marcogll/scripts_mg/main/omarchy_zsh_setup/omarchy-setup.sh)
```

🚀 **¡Disfruta tu nuevo setup de Omarchy!**
