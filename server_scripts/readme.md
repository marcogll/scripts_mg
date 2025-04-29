# 🚀 Auto Server Setup — Ubuntu 22.04 / 24.04 LTS

Script de instalación **totalmente desatendida** que convierte una instancia limpia de Ubuntu Server en un _home-server_ completo con:

| Bloque | Paquetes / Servicios                                                                 |
|--------|--------------------------------------------------------------------------------------|
| Base   | `git` `curl` `nano` `gnupg` `ca-certificates` …                                       |
| Shell  | **Zsh**, Oh-My-Zsh, `zsh-autosuggestions`                                            |
| Utils  | `fzf`, `btop`                                                                        |
| SSL    | **Certbot** (Let’s Encrypt, vía **snap**)                                            |
| Docker | Docker Engine + compose-plugin (repo oficial)                                        |
| Red    | **ZeroTier One** (P2P VPN)                                                           |
| UI     | **Portainer CE** (contenedor)                                                        |
| Apps   | **CasaOS** *(opcional)*, **Pi-hole** *(opcional, nativo)*, **Plex Media Server**     |

---

## ⚡ Instalación en una sola línea

```bash
curl -fsSL https://raw.githubusercontent.com/marcogll/scripts_mg/main/server_scripts/auto_serveretup.sh \
  -o auto_server_setup.sh && chmod +x auto_server_setup.sh && sudo ./auto_server_setup.sh

