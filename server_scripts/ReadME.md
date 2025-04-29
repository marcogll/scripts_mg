# 🚀 Auto Server Setup — Ubuntu 22.04 / 24.04 LTS

## ⚡ Instalación rápida

Copia y pega en tu terminal (sesión **root** o con `sudo`):

```bash
curl -fsSL https://raw.githubusercontent.com/marcogll/scripts_mg/main/server_scripts/auto_server_setup.sh \
  -o auto_server_setup.sh && chmod +x auto_server_setup.sh && sudo ./auto_server_setup.sh
```

---

## 📦 ¿Qué instala?

| Bloque | Paquetes / Servicios |
| ------ | ------------------- |
| **Base** | `git` `curl` `nano` `gnupg` `ca-certificates` … |
| **Shell** | **Zsh**, Oh‑My‑Zsh, `zsh‑autosuggestions` |
| **Utils** | `fzf`, `btop` |
| **SSL** | **Certbot** (Let’s Encrypt, vía **snap**) |
| **Docker** | Docker Engine + compose‑plugin (repo oficial) |
| **Red** | **ZeroTier One** (VPN P2P) |
| **UI** | **Portainer CE** (contenedor) |
| **Apps** | **CasaOS** *(opcional)*, **Pi‑hole** *(opcional, nativo)*, **Plex Media Server* |

---

## 🧩 Lógica del orden

1. **Base APT** – actualiza el sistema y añade utilidades básicas.
2. **Shell + Utils** – mejora la experiencia de terminal antes de tareas largas.
3. **Certbot** – ocupa el puerto 80 para los retos HTTP‑01; se instala temprano.
4. **Docker** – prerequisito de Portainer y CasaOS.
5. **ZeroTier** – habilita acceso remoto P2P seguro.
6. **Portainer** – despliegue de UI Docker (contenedor).
7. **CasaOS** *(opcional)* – dashboard doméstico que detecta Docker.
8. **Pi‑hole** *(opcional)* – DNS sinkhole nativo.
9. **Plex** – servicio systemd desde repo oficial.
10. **Reinicio** – automático si `AUTO_REBOOT=yes`.

---

## 🔧 Variables rápidas dentro del script

```bash
SERVER_USER="marco"   # usuario añadido a los grupos docker/zerotier
INSTALL_PIHOLE="yes"  # "no" para omitir Pi-hole
INSTALL_CASAOS="yes"  # "no" para omitir CasaOS
AUTO_REBOOT="yes"     # "no" para reiniciar manualmente
```

---

## 🎯 Accesos post‑instalación

| Servicio | URL por defecto |
| -------- | --------------- |
| Portainer | `https://<IP-servidor>:9443` |
| CasaOS | `http://<IP-servidor>` *(si lo instalaste)* |
| Plex | `http://<IP-servidor>:32400/web` |
| Pi‑hole | `http://<IP-servidor>/admin` *(si lo instalaste)* |

---

## 🛡️ Notas de seguridad

* **Certbot** se instala vía *snap*; emite tus certificados así:
  ```bash
  sudo certbot certonly --standalone -d ejemplo.com -m tu@email.com
  ```
* **ZeroTier** no une automáticamente tu servidor a ninguna red. Hazlo con:
  ```bash
  sudo zerotier-cli join <NETWORK_ID>
  ```
* El script importa claves GPG y repos oficiales para cada componente.

---

## 📄 Licencia

MIT — puedes usar, modificar y redistribuir libremente este script.

