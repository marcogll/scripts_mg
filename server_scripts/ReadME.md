# 🚀 Auto Server Setup — Ubuntu 22.04 / 24.04 LTS

Script **pull-&-run** que convierte un Ubuntu Server limpio en un _home-server_ completo.  
Incluye barra de progreso con emojis y funciona **interactivo** (te pregunta) o **100 % desatendido** (dejas los valores por defecto).

---

## ⚡ Instalación rápida

```bash
curl -fsSL https://raw.githubusercontent.com/marcogll/scripts_mg/main/server_scripts/auto_server_setup.sh \
  -o auto_server_setup.sh && chmod +x auto_server_setup.sh && sudo ./auto_server_setup.sh
````

---

## 📦 ¿Qué instala?

| Bloque     | Paquetes / Servicios                                                   | Descripción breve                  |
| ---------- | ---------------------------------------------------------------------- | ---------------------------------- |
| **Base**   | `git` `curl` `nano` `gnupg` `fontconfig` …                             | Herramientas esenciales            |
| **Shell**  | **Zsh**, Oh-My-Zsh, `zsh-autosuggestions`, **Oh-My-Posh** + *Meslo NF* | Prompt avanzado                    |
| **Utils**  | `fzf`, `btop`                                                          | Búsqueda difusa · Monitor recursos |
| **SSL**    | **Certbot** (Let’s Encrypt vía **snap**)                               | Certificados TLS                   |
| **Docker** | Docker Engine + compose-plugin                                         | Contenedores                       |
| **Red**    | **ZeroTier One**                                                       | VPN P2P                            |
| **UI**     | **Portainer CE** *(contenedor)*                                        | Dashboard Docker                   |
| **Apps**   | **CasaOS** *(opcional)* · **Pi-hole** *(opcional, nativo)* · **Plex**  | Servicios domésticos               |

---

## 🧩 Lógica del orden

1. **Base APT** – actualiza el SO y añade utilidades básicas.
2. **Shell + Utils** – mejora la terminal antes de tareas largas.
3. **Certbot** – reserva el puerto 80 para retos HTTP-01.
4. **Docker** – prerequisito de Portainer y CasaOS.
5. **ZeroTier** – acceso remoto P2P seguro.
6. **Portainer** – UI Docker (contenedor).
7. **CasaOS** *(opcional)* – dashboard doméstico.
8. **Pi-hole** *(opcional)* – DNS sinkhole nativo.
9. **Plex** – servicio systemd del repo oficial.
10. **Reinicio** – automático si `AUTO_REBOOT=yes`.

---

## 🔧 Variables rápidas en el script

```bash
SERVER_USER="marco"   # usuario agregado a docker/zerotier
INSTALL_PIHOLE="yes"  # "no" para omitir Pi-hole
INSTALL_CASAOS="yes"  # "no" para omitir CasaOS
AUTO_REBOOT="yes"     # "no" para reiniciar manualmente
```

*(en modo interactivo el script te pregunta estos valores al inicio).*

---

## 🎯 Accesos post-instalación

| Servicio  | URL por defecto                                   |
| --------- | ------------------------------------------------- |
| Portainer | `https://<IP-servidor>:9443`                      |
| CasaOS    | `http://<IP-servidor>` *(si lo instalaste)*       |
| Plex      | `http://<IP-servidor>:32400/web`                  |
| Pi-hole   | `http://<IP-servidor>/admin` *(si lo instalaste)* |

---

## 🛡️ Notas de seguridad

* **Certbot** — emite tus certificados así:

  ```bash
  sudo certbot certonly --standalone -d ejemplo.com -m tu@email.com
  ```
* **ZeroTier** — únete a tu red manualmente:

  ```bash
  sudo zerotier-cli join <NETWORK_ID>
  ```
* El script añade repos y claves GPG oficiales para cada componente.

---

## ♻️ Desinstalación completa

Si quieres revertir todo y dejar el sistema casi como recién instalado utiliza el script de *reset*:

```bash
curl -fsSL https://raw.githubusercontent.com/marcogll/scripts_mg/main/server_scripts/auto_server_reset.sh \
  -o auto_server_reset.sh && chmod +x auto_server_reset.sh && sudo ./auto_server_reset.sh
```

Este script:

1. Detiene y elimina contenedores/volúmenes Docker.
2. Purga Docker, Portainer, ZeroTier, Tailscale, Plex, Samba, Certbot, etc.
3. Desinstala CasaOS y Pi-hole (si existían).
4. Limpia Oh-My-Zsh/Posh, fuentes Meslo y alias del `.zshrc`.
5. Ejecuta `apt autoremove` y te ofrece reiniciar al final.

> ⚠️ **Destructivo**: borra configuraciones y datos de los servicios listados.
> Haz copias de seguridad antes de continuar.

---

## 📄 Licencia
MIT — úsalo, modifícalo y compártelo libremente.
