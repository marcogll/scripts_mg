# 🚀 Auto Server Setup — Ubuntu 22.04 / 24.04 LTS

Script **pull-&-run** que transforma una instalación limpia de **Ubuntu Server**
en un _home-server_ completo.  
Incluye barra de progreso con emojis y puede ejecutarse **interactivo** (te hace
preguntas) o **100 % desatendido** si dejas los valores por defecto.

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
| **SSL**    | **Certbot** (Let’s Encrypt, vía **snap**)                              | Certificados TLS                   |
| **Docker** | Docker Engine + compose-plugin                                         | Contenedores                       |
| **Red**    | **ZeroTier One**                                                       | VPN P2P                            |
| **UI**     | **Portainer CE** *(contenedor)*                                        | Dashboard Docker                   |
| **Apps**   | **CasaOS** *(opcional)* · **Pi-hole** *(opcional, nativo)* · **Plex**  | Servicios domésticos               |

---

## 🧩 Lógica del orden

1. **Base APT** – actualiza el sistema y añade utilidades básicas.
2. **Shell + Utils** – mejora la experiencia de terminal antes de tareas largas.
3. **Certbot** – ocupa el puerto 80 para retos HTTP-01; se instala temprano.
4. **Docker** – prerequisito de Portainer y CasaOS.
5. **ZeroTier** – habilita acceso remoto P2P seguro.
6. **Portainer** – despliegue de UI Docker (contenedor).
7. **CasaOS** *(opcional)* – dashboard doméstico que detecta Docker.
8. **Pi-hole** *(opcional)* – DNS sinkhole nativo.
9. **Plex** – servicio systemd desde repo oficial.
10. **Reinicio** – automático si `AUTO_REBOOT=yes`.

---

## 🔧 Variables rápidas dentro del script

```bash
SERVER_USER="marco"   # usuario añadido a los grupos docker/zerotier
INSTALL_PIHOLE="yes"  # "no" para omitir Pi-hole
INSTALL_CASAOS="yes"  # "no" para omitir CasaOS
AUTO_REBOOT="yes"     # "no" para reiniciar manualmente
```

*(en modo interactivo te las pregunta al inicio; déjalas o cámbialas a mano
para modo headless).*

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

* **Certbot** se instala vía *snap*; emite tus certificados así:

  ```bash
  sudo certbot certonly --standalone -d ejemplo.com -m tu@email.com
  ```

* **ZeroTier** no une automáticamente tu servidor a ninguna red. Hazlo con:

  ```bash
  sudo zerotier-cli join <NETWORK_ID>
  ```

* El script importa claves GPG y repos oficiales antes de cada paquete.

---

## 📄 Licencia

MIT — siéntete libre de usar, modificar y redistribuir.

```
```
