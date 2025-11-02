# 🚀 Omarchy Zsh Setup Script v2.8.1

Script de instalación y configuración completa para **Omarchy Linux** con Zsh, Oh My Posh, y todas las herramientas esenciales.

Versión unificada que combina la estética Catppuccin con la robustez y características de versiones anteriores.

## ⚡ Instalación rápida

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/marcogll/scripts_mg/main/omarchy_zsh_setup/omarchy-setup.sh)
```

---

## ✨ Características

### 🎨 Terminal y Shell
- **Zsh** + **Oh My Zsh** + plugins (autosuggestions, syntax-highlighting)
- **Oh My Posh** con tema Catppuccin Frappe desde AUR
- Configuración `.zshrc` personalizada desde GitHub
- Aliases útiles para Arch, Git, Docker, NPM, Python, ZeroTier

### 🔐 Seguridad y Red
- **ZeroTier One** con configuración interactiva desde AUR
- **GNOME Keyring** configurado para Git/SSH
- Configuración automática de claves SSH con el agente

### 🛠️ Desarrollo
- Git, Docker, Docker Compose
- Node.js, NPM
- Python, pip, virtualenv, Go
- **yay** (AUR helper)

### 😊 Utilidades
- **yt-dlp** para descargar audio/video de YouTube
- Fastfetch, htop, btop para monitoreo del sistema
- eza, bat, zoxide, tree para navegación mejorada
- playerctl, brightnessctl, pamixer para control multimedia

### 📦 Servicios
- **Docker** configurado y usuario añadido al grupo
- **TeamViewer** servicio habilitado
- **ZeroTier One** VPN configurada

---

## 📦 Paquetes instalados

<details>
<summary>Ver lista completa (click para expandir)</summary>

### Sistema Base
- **zsh**, **zsh-completions**
- **oh-my-posh-bin** (desde AUR)
- **git**, **curl**, **wget**
- **yay** (AUR helper, compilado desde AUR)

### Desarrollo
- **python**, **python-pip**, **python-virtualenv**
- **nodejs**, **npm**
- **go** (Golang)
- **docker**, **docker-compose**
- **base-devel** (herramientas de compilación)

### Utilidades de Terminal
- **eza** (ls mejorado)
- **bat** (cat mejorado)
- **zoxide** (cd inteligente)
- **fastfetch** (info del sistema)
- **htop**, **btop** (monitores del sistema)
- **tree** (visualización de directorios)

### Multimedia y Control
- **yt-dlp**, **ffmpeg**
- **playerctl**, **brightnessctl**, **pamixer**
- **audacity**, **inkscape**

### Red y Seguridad
- **zerotier-one** (desde AUR)
- **gnome-keyring**, **libsecret**, **seahorse**
- **lsof**, **net-tools**
- **teamviewer**

### Utilidades del Sistema
- **nano**, **unzip**, **tar**
- **p7zip**, **unrar**

### Instalaciones Adicionales
- **speedtest-cli** (vía pip)

</details>

---

## 🎯 Durante la instalación

El script ejecuta los siguientes pasos:

1. **Verificación de requerimientos** (root, Arch Linux, conexión a Internet)
2. **Instalación de paquetes base** desde repositorios oficiales
3. **Instalación de yay** desde AUR (si no está instalado)
4. **Configuración de Docker** (servicio y permisos de usuario)
5. **Instalación de Oh My Zsh y plugins**
6. **Configuración de .zshrc y tema Catppuccin** desde GitHub
7. **Configuración de TeamViewer** (servicio)
8. **Instalación de ZeroTier One** desde AUR (opcional)
9. **Configuración de GNOME Keyring** (opcional)
10. **Configuración de claves SSH** (opcional)

### Preguntas interactivas:

- **ZeroTier Network ID**: Si deseas unirte a una red ZeroTier (opcional)
- **GNOME Keyring**: Si deseas configurar el almacén de contraseñas
- **Claves SSH**: Si deseas añadir claves SSH existentes al agente

---

## 🔑 GNOME Keyring

El keyring guarda contraseñas de forma segura:
- **Git** (credential helper)
- **SSH keys** (almacenadas de forma segura)
- **Aplicaciones GNOME**

### Configuración automática:

El script configura automáticamente:
- PAM para auto-desbloqueo del keyring
- Inicio automático de gnome-keyring-daemon
- Integración con SSH agent

### Comandos útiles:

```bash
# Abrir gestor de contraseñas
seahorse

# Ver estado del keyring
gnome-keyring-daemon --version

# Comandos de ZeroTier (aliases en .zshrc)
zt              # Alias de sudo zerotier-cli
ztstatus        # Ver redes conectadas (listnetworks)
ztinfo          # Info del nodo (info)
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
ytv <URL>           # Descargar video MP4 (calidad por defecto)
ytv <URL> 1080      # Descargar video en 1080p
ytv <URL> 720       # Descargar video en 720p
ytls                # Listar últimos descargas
```

Descargas en: `~/Videos/YouTube/{Music,Videos}/`

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
├── .zshrc                          # Configuración de Zsh (descargado desde GitHub)
├── .zshrc.local                   # Config local (opcional, no creado automáticamente)
├── .oh-my-zsh/                    # Oh My Zsh
│   └── custom/plugins/            # Plugins adicionales
│       ├── zsh-autosuggestions/
│       └── zsh-syntax-highlighting/
├── .poshthemes/                   # Temas Oh My Posh
│   └── catppuccin.omp.json        # Tema Catppuccin Frappe
├── .zsh_functions/                # Funciones personalizadas (directorio creado)
├── Videos/YouTube/                # Descargas de yt-dlp
│   ├── Music/                     # Audios MP3
│   └── Videos/                    # Videos MP4
├── .ssh/                          # Claves SSH (si existen)
└── omarchy-setup.log             # Log de instalación
```

---

## 🔄 Después de la instalación

### 1. Reiniciar sesión o terminal (IMPORTANTE)

**⚠️ REINICIO REQUERIDO** si se instalaron servicios como TeamViewer o ZeroTier.

```bash
# Cerrar y volver a abrir la terminal para usar Zsh
# O cerrar sesión y volver a entrar para aplicar:
# - Cambio de shell a Zsh
# - Grupos (docker)
# - Permisos del sistema
```

### 2. Verificar instalación

```bash
# Ver versión de Zsh
zsh --version

# Ver tema Oh My Posh
oh-my-posh version

# Verificar Docker
docker ps

# Ver ZeroTier (si se configuró)
ztstatus

# Ver TeamViewer (si se instaló)
teamviewer info

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

### Docker no funciona sin sudo

```bash
# Verificar que estás en el grupo docker
groups  # Debe incluir 'docker'

# Si no aparece, reinicia sesión o ejecuta:
newgrp docker

# Verificar acceso
docker ps
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

# Verificar que el keyring está corriendo
pgrep -u "$USER" gnome-keyring-daemon
```

### ZeroTier no conecta

```bash
# Verificar servicio
sudo systemctl status zerotier-one

# Ver logs
sudo journalctl -u zerotier-one -f

# Reiniciar servicio
sudo systemctl restart zerotier-one

# Verificar que autorizaste el nodo en https://my.zerotier.com
ztinfo
ztstatus
```

### Oh My Posh no se muestra correctamente

```bash
# Verificar instalación
which oh-my-posh
oh-my-posh version

# Verificar que el tema existe
ls ~/.poshthemes/catppuccin.omp.json

# Verificar que tienes una Nerd Font instalada
# (El script NO instala fuentes automáticamente)
fc-list | grep -i nerd

# Si no tienes Nerd Font, instala una:
# - Nerd Fonts: https://www.nerdfonts.com/
```

### El shell no cambió a Zsh

```bash
# Verificar shell actual
echo $SHELL

# Cambiar manualmente
chsh -s $(which zsh)

# Cerrar y abrir nueva terminal
```

---

## 📚 Recursos

- **Arch Wiki**: https://wiki.archlinux.org/
- **Oh My Zsh**: https://ohmyz.sh/
- **Oh My Posh**: https://ohmyposh.dev/
- **Catppuccin Theme**: https://github.com/catppuccin/catppuccin
- **ZeroTier**: https://www.zerotier.com/
- **yt-dlp**: https://github.com/yt-dlp/yt-dlp
- **Nerd Fonts**: https://www.nerdfonts.com/ (requerido para iconos del prompt)
- **yay AUR Helper**: https://github.com/Jguer/yay

---

## 🆘 Soporte

Si encuentras problemas:

1. Revisa los logs del script durante la instalación
2. Verifica que cerraste sesión después de instalar
3. Comprueba que los grupos se aplicaron: `groups`
4. Abre un issue en: https://github.com/marcogll/scripts_mg/issues

---

## 📝 Changelog

### v2.8.1 (2025-11-02)
- Versión unificada con estética Catppuccin
- Instalación mejorada de paquetes con manejo de errores robusto
- **oh-my-posh** instalado desde AUR automáticamente
- Configuración `.zshrc` descargada desde GitHub
- Instalación de plugins Zsh mejorada
- Configuración de ZeroTier One desde AUR
- Configuración opcional de GNOME Keyring y SSH
- **Nota importante**: Instalación de Nerd Fonts omitida (requiere instalación manual)
- Script no se detiene ante errores menores, continúa con advertencias
- Mejor manejo de errores en instalación de paquetes individuales

---

## 📄 Licencia

MIT License - Libre de usar y modificar

---

## 👤 Autor

**Marco**
- GitHub: [@marcogll](https://github.com/marcogll)
- Repo: [scripts_mg](https://github.com/marcogll/scripts_mg)

---


```bash
# Instalar en una línea
bash <(curl -fsSL https://raw.githubusercontent.com/marcogll/scripts_mg/main/omarchy_zsh_setup/omarchy-setup.sh)
```

## 📝 Notas importantes

- **Fuentes Nerd Font**: El script NO instala fuentes automáticamente. Asegúrate de tener una Nerd Font instalada manualmente para que los iconos del prompt se vean correctamente.
- **Reinicio requerido**: Si se instalaron servicios como TeamViewer o ZeroTier, se recomienda reiniciar el sistema.
- **Shell por defecto**: El script verifica si zsh es el shell por defecto, pero no lo cambia automáticamente para evitar bloqueos. Ejecuta manualmente `chsh -s $(which zsh)` si es necesario.

🚀 **¡Disfruta tu nuevo setup de Omarchy con Catppuccin!**
