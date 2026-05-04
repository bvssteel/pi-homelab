# 🏠 Pi Homelab

A fully automated Raspberry Pi 5 home server setup. Run one script and get a complete self-hosted homelab with Docker, a beautiful dashboard, smart home hub, automation workflows, local AI, ad blocking, and more.

---

## ✨ Features

| Service | Purpose | Port |
|---|---|---|
| [Homepage](https://github.com/gethomepage/homepage) | Homelab dashboard | 3005 |
| [Portainer](https://github.com/portainer/portainer) | Docker management UI | 9443 |
| [Home Assistant](https://github.com/home-assistant/core) | Smart home hub | 8123 |
| [n8n](https://github.com/n8n-io/n8n) | Workflow automation | 5678 |
| [Pi-hole](https://github.com/pi-hole/pi-hole) | Network-wide ad blocking | 8053 |
| [Nginx Proxy Manager](https://github.com/NginxProxyManager/nginx-proxy-manager) | Reverse proxy | 81 |
| [Vaultwarden](https://github.com/dani-garcia/vaultwarden) | Self-hosted password manager | 8080 |
| [Uptime Kuma](https://github.com/louislam/uptime-kuma) | Service monitoring | 3001 |
| [Nextcloud](https://github.com/nextcloud/server) | Self-hosted cloud storage | 8181 |
| [Stirling PDF](https://github.com/Stirling-Tools/Stirling-PDF) | PDF tools | 8888 |
| [Ollama](https://github.com/ollama/ollama) | Local LLM engine | 11434 |
| [Open WebUI](https://github.com/open-webui/open-webui) | Local AI chat interface | 3000 |
| [Watchtower](https://github.com/containrrr/watchtower) | Auto-update containers | - |
| [Tailscale](https://tailscale.com) | Secure remote access | - |
| [Netdata](https://github.com/netdata/netdata) | Real-time system monitoring | 19999 |

---

## 🛒 Requirements

### Hardware
- Raspberry Pi 5 (4GB or 8GB recommended)
- MicroSD card (32GB+ recommended, SanDisk Extreme or similar quality card)
- USB-C power supply (5V 5A / 25W — official Pi 5 supply recommended)
- Ethernet or WiFi connection

### Software
- [Raspberry Pi Imager](https://www.raspberrypi.com/software/) (on your PC/Mac)
- SSH client (PuTTY on Windows, Terminal on Mac/Linux)

---

## 🚀 Quick Start

### Step 1 — Flash the OS

1. Download and open [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. Select **Raspberry Pi 5** as the device
3. Select **Raspberry Pi OS (64-bit)** as the OS
4. Select your SD card as storage
5. Click the **settings cog** and configure:
   - Hostname: `homelab` (or your preferred name)
   - Username and password
   - WiFi credentials
   - Enable SSH ✓
6. Flash the card and insert into your Pi
7. Power on and wait 2-3 minutes for first boot

### Step 2 — Connect via SSH

```bash
ssh yourusername@homelab.local
```

### Step 3 — Run the setup script

```bash
curl -fsSL https://raw.githubusercontent.com/Elhard1/pi-homelab/main/setup.sh | bash
```

That's it! The script handles everything from here. It will prompt you for:
- Your preferred hostname
- Pi-hole admin password
- n8n admin password
- Tailscale authentication (opens a URL in your browser)

---

## 📋 What the Script Does

1. Updates the system packages
2. Installs Docker and Docker Compose
3. Adds your user to the Docker group
4. Installs Tailscale for secure remote access
5. Installs Netdata for real-time system monitoring
6. Creates the homelab directory and Docker Compose stack
7. Configures Homepage dashboard with all service links
8. Pulls all Docker images
9. Starts all services
10. Prints a summary of all service URLs

---

## 🌐 Accessing Your Services

After setup, access your services at (replace `homelab` with your hostname):

```
http://homelab.local:3005        — Homepage Dashboard (start here!)
http://homelab.local:8123        — Home Assistant
http://homelab.local:5678        — n8n Automation
http://homelab.local:81          — Nginx Proxy Manager
http://homelab.local:8080        — Vaultwarden Password Manager
http://homelab.local:3001        — Uptime Kuma Monitoring
http://homelab.local:8181        — Nextcloud
http://homelab.local:8888        — Stirling PDF
http://homelab.local:3000        — Open WebUI (Local AI)
http://homelab.local:8053/admin  — Pi-hole
http://homelab.local:19999       — Netdata
https://homelab.local:9443       — Portainer
```

---

## 🔒 Remote Access with Tailscale

The setup script installs Tailscale automatically. After installation:

1. You'll be given a Tailscale auth URL — open it and sign in
2. Install Tailscale on your phone/laptop from [tailscale.com/download](https://tailscale.com/download)
3. Access your homelab from anywhere using your Pi's Tailscale IP (`100.x.x.x`)

Works through Starlink, 4G, CGNAT — no port forwarding required.

---

## 🛡️ Pi-hole Ad Blocking

After setup, configure your router to use your Pi as its DNS server:

1. Find your Pi's local IP address: `hostname -I`
2. Log into your router admin page (usually `192.168.0.1` or `192.168.1.1`)
3. Find DNS settings (usually under LAN or DHCP settings)
4. Set Primary DNS to your Pi's IP address
5. All devices on your network will now use Pi-hole automatically

Access the Pi-hole dashboard at `http://homelab.local:8053/admin`

---

## 🤖 Using Local AI (Ollama)

After setup, pull your first model:

```bash
docker exec -it ollama ollama pull llama3.2
```

Then open Open WebUI at `http://homelab.local:3000` to chat with it.

**Recommended models for Pi 5 8GB:**
- `llama3.2` — 3B, best balance of speed and quality (~2GB)
- `phi3` — fast and efficient (~2.3GB)
- `mistral` — good general purpose model (~4GB)

> Note: Models load from storage into RAM. Initial load takes 30-60 seconds but inference speed is CPU-limited, not storage-limited.

---

## 🔧 Default Credentials

> ⚠️ Change these immediately after setup!

| Service | Username | Password |
|---|---|---|
| n8n | admin | set during setup |
| Nginx Proxy Manager | admin@example.com | changeme |
| Pi-hole | - | set during setup |

---

## 📁 File Structure

```
pi-homelab/
├── setup.sh                      # Main automated setup script
├── docker-compose.yml            # Full Docker stack definition
├── config/
│   └── homepage/
│       └── services.yaml         # Homepage dashboard config
├── docs/
│   └── manual-setup.md           # Step-by-step manual setup guide
└── README.md
```

---

## 📦 Updating Services

Watchtower automatically updates all containers at 4am daily.

To manually update all services:

```bash
cd ~/homelab && docker compose pull && docker compose up -d
```

To update a single service:

```bash
cd ~/homelab && docker compose pull <service-name> && docker compose up -d <service-name>
```

---

## 🛠️ Useful Commands

```bash
# View all running containers
docker ps

# View logs for a service
docker logs <container-name> --tail 50

# Restart a service
docker restart <container-name>

# Stop all services
cd ~/homelab && docker compose down

# Start all services
cd ~/homelab && docker compose up -d

# Check Pi system stats
htop

# Check disk usage
df -h

# Check Tailscale status
tailscale status
```

---

## 🙏 Attributions

This project uses the following open source projects:

- [Homepage](https://github.com/gethomepage/homepage) — MIT License
- [Portainer CE](https://github.com/portainer/portainer) — zlib License
- [Home Assistant](https://github.com/home-assistant/core) — Apache 2.0 License
- [n8n](https://github.com/n8n-io/n8n) — Sustainable Use License
- [Pi-hole](https://github.com/pi-hole/pi-hole) — EUPL License
- [Nginx Proxy Manager](https://github.com/NginxProxyManager/nginx-proxy-manager) — MIT License
- [Vaultwarden](https://github.com/dani-garcia/vaultwarden) — AGPL-3.0 License
- [Uptime Kuma](https://github.com/louislam/uptime-kuma) — MIT License
- [Nextcloud](https://github.com/nextcloud/server) — AGPL-3.0 License
- [Stirling PDF](https://github.com/Stirling-Tools/Stirling-PDF) — MIT License
- [Ollama](https://github.com/ollama/ollama) — MIT License
- [Open WebUI](https://github.com/open-webui/open-webui) — MIT License
- [Watchtower](https://github.com/containrrr/watchtower) — Apache 2.0 License
- [Tailscale](https://tailscale.com) — BSD 3-Clause License
- [Netdata](https://github.com/netdata/netdata) — GPL-3.0 License

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.
