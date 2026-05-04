#!/bin/bash

# =============================================================
# Pi Homelab Setup Script
# Automated Raspberry Pi 5 home server setup
# https://github.com/Elhard1/pi-homelab
# =============================================================

set -e

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "  ____  _   _   _  _                 _       _     "
echo " |  _ \(_) | | | || | ___  _ __ ___  | | __ _| |__  "
echo " | |_) | | | |_| || |/ _ \| '_ \` _ \ | |/ _\` | '_ \ "
echo " |  __/| | |  _  || | (_) | | | | | || | (_| | |_) |"
echo " |_|   |_| |_| |_||_|\___/|_| |_| |_||_|\__,_|_.__/ "
echo ""
echo -e "${NC}"
echo -e "${GREEN}Raspberry Pi 5 Home Server Setup${NC}"
echo "================================================="
echo ""

# =============================================================
# COLLECT USER INPUT
# =============================================================

read -p "Enter your hostname (default: homelab): " HOSTNAME
HOSTNAME=${HOSTNAME:-homelab}

read -s -p "Enter Pi-hole admin password: " PIHOLE_PASSWORD
echo ""

read -s -p "Enter n8n admin password: " N8N_PASSWORD
echo ""

# Get local IP
LOCAL_IP=$(hostname -I | awk '{print $1}')
echo -e "\n${GREEN}Detected IP: ${LOCAL_IP}${NC}"

# =============================================================
# STEP 1 — SYSTEM UPDATE
# =============================================================

echo -e "\n${YELLOW}[1/9] Updating system packages...${NC}"
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git nano htop

# =============================================================
# STEP 2 — INSTALL DOCKER
# =============================================================

echo -e "\n${YELLOW}[2/9] Installing Docker...${NC}"
curl -sSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Disable IPv6 for Docker to avoid pull issues
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "ipv6": false,
  "ip": "0.0.0.0"
}
EOF
sudo systemctl restart docker
sleep 3

echo -e "${GREEN}Docker installed successfully${NC}"

# =============================================================
# STEP 3 — INSTALL TAILSCALE
# =============================================================

echo -e "\n${YELLOW}[3/9] Installing Tailscale...${NC}"
curl -fsSL https://tailscale.com/install.sh | sh
echo -e "${GREEN}Tailscale installed. Authenticate with the URL below:${NC}"
sudo tailscale up

# =============================================================
# STEP 4 — INSTALL NETDATA
# =============================================================

echo -e "\n${YELLOW}[4/9] Installing Netdata...${NC}"
curl https://get.netdata.cloud/kickstart.sh > /tmp/netdata-kickstart.sh
sudo sh /tmp/netdata-kickstart.sh --non-interactive
echo -e "${GREEN}Netdata installed${NC}"

# =============================================================
# STEP 5 — CREATE HOMELAB DIRECTORY
# =============================================================

echo -e "\n${YELLOW}[5/9] Creating homelab directory...${NC}"
mkdir -p ~/homelab

# =============================================================
# STEP 6 — CREATE DOCKER COMPOSE FILE
# =============================================================

echo -e "\n${YELLOW}[6/9] Creating Docker Compose stack...${NC}"

cat > ~/homelab/docker-compose.yml << COMPOSE
services:

  # --- Portainer - Docker Management UI ---
  portainer:
    image: portainer/portainer-ce:2.21.5-alpine
    container_name: portainer
    restart: always
    ports:
      - "8000:8000"
      - "9443:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data

  # --- Watchtower - Auto Update Containers ---
  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_SCHEDULE=0 0 4 * * *
      - TZ=Australia/Perth

  # --- Home Assistant - Smart Home Hub ---
  homeassistant:
    image: ghcr.io/home-assistant/home-assistant:stable
    container_name: homeassistant
    restart: unless-stopped
    network_mode: host
    environment:
      - TZ=Australia/Perth
    volumes:
      - homeassistant_config:/config
    privileged: true

  # --- Nginx Proxy Manager - Reverse Proxy ---
  nginx-proxy-manager:
    image: jc21/nginx-proxy-manager:latest
    container_name: nginx-proxy-manager
    restart: unless-stopped
    ports:
      - "80:80"
      - "81:81"
      - "443:443"
    volumes:
      - npm_data:/data
      - npm_letsencrypt:/etc/letsencrypt

  # --- n8n - Automation Workflows ---
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - TZ=Australia/Perth
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
      - N8N_HOST=0.0.0.0
      - WEBHOOK_URL=http://${HOSTNAME}.local:5678
    volumes:
      - n8n_data:/home/node/.n8n

  # --- Pi-hole - Network Ad Blocking ---
  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    restart: always
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "8053:80"
    environment:
      - TZ=Australia/Perth
      - WEBPASSWORD=${PIHOLE_PASSWORD}
    volumes:
      - pihole_data:/etc/pihole
      - pihole_dnsmasq:/etc/dnsmasq.d
    dns:
      - 127.0.0.1
      - 1.1.1.1

  # --- Vaultwarden - Self Hosted Password Manager ---
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
    ports:
      - "8080:80"
    environment:
      - TZ=Australia/Perth
      - WEBSOCKET_ENABLED=true
    volumes:
      - vaultwarden_data:/data

  # --- Uptime Kuma - Service Monitoring ---
  uptime-kuma:
    image: louislam/uptime-kuma:latest
    container_name: uptime-kuma
    restart: unless-stopped
    ports:
      - "3001:3001"
    volumes:
      - uptime_kuma_data:/app/data

  # --- Stirling PDF - PDF Tools ---
  stirling-pdf:
    image: frooodle/s-pdf:latest
    container_name: stirling-pdf
    restart: unless-stopped
    ports:
      - "8888:8080"
    volumes:
      - stirling_data:/configs

  # --- Nextcloud - Self Hosted Cloud Storage ---
  nextcloud:
    image: nextcloud:latest
    container_name: nextcloud
    restart: unless-stopped
    ports:
      - "8181:80"
    environment:
      - TZ=Australia/Perth
      - MYSQL_HOST=nextcloud-db
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_PASSWORD=nextcloud_password
    volumes:
      - nextcloud_data:/var/www/html
    depends_on:
      - nextcloud-db

  # --- Nextcloud Database ---
  nextcloud-db:
    image: mariadb:10.11
    container_name: nextcloud-db
    restart: unless-stopped
    environment:
      - MYSQL_ROOT_PASSWORD=root_password
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_PASSWORD=nextcloud_password
    volumes:
      - nextcloud_db_data:/var/lib/mysql

  # --- Ollama - Local LLM Engine ---
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    environment:
      - TZ=Australia/Perth

  # --- Open WebUI - Chat Interface for Ollama ---
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    restart: unless-stopped
    ports:
      - "3000:8080"
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
      - TZ=Australia/Perth
    volumes:
      - open_webui_data:/app/backend/data
    depends_on:
      - ollama

  # --- Homepage - Service Dashboard ---
  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    restart: unless-stopped
    ports:
      - "3005:3000"
    volumes:
      - homepage_config:/app/config
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - TZ=Australia/Perth
      - HOMEPAGE_ALLOWED_HOSTS=${HOSTNAME}.local:3005,${LOCAL_IP}:3005

volumes:
  portainer_data:
  homeassistant_config:
  npm_data:
  npm_letsencrypt:
  n8n_data:
  pihole_data:
  pihole_dnsmasq:
  vaultwarden_data:
  uptime_kuma_data:
  stirling_data:
  nextcloud_data:
  nextcloud_db_data:
  ollama_data:
  open_webui_data:
  homepage_config:
COMPOSE

echo -e "${GREEN}Docker Compose file created${NC}"

# =============================================================
# STEP 7 — CONFIGURE HOMEPAGE DASHBOARD
# =============================================================

echo -e "\n${YELLOW}[7/9] Configuring Homepage dashboard...${NC}"

# Pull and start homepage first to create config volume
docker compose -f ~/homelab/docker-compose.yml pull homepage
docker compose -f ~/homelab/docker-compose.yml up -d homepage
sleep 5

# Write services config
docker exec -it homepage sh -c "cat > /app/config/services.yaml << 'EOF'
- Management:
    - Portainer:
        href: https://${LOCAL_IP}:9443
        description: Docker Management
        icon: portainer.png
    - Nginx Proxy Manager:
        href: http://${LOCAL_IP}:81
        description: Reverse Proxy
        icon: nginx-proxy-manager.png

- Automation:
    - n8n:
        href: http://${LOCAL_IP}:5678
        description: Workflow Automation
        icon: n8n.png
    - Home Assistant:
        href: http://${LOCAL_IP}:8123
        description: Smart Home Hub
        icon: home-assistant.png

- Monitoring:
    - Uptime Kuma:
        href: http://${LOCAL_IP}:3001
        description: Service Monitoring
        icon: uptime-kuma.png
    - Netdata:
        href: http://${LOCAL_IP}:19999
        description: System Performance
        icon: netdata.png
    - Pi-hole:
        href: http://${LOCAL_IP}:8053/admin
        description: Ad Blocking
        icon: pi-hole.png

- Storage and Tools:
    - Nextcloud:
        href: http://${LOCAL_IP}:8181
        description: Self Hosted Cloud
        icon: nextcloud.png
    - Vaultwarden:
        href: http://${LOCAL_IP}:8080
        description: Password Manager
        icon: vaultwarden.png
    - Stirling PDF:
        href: http://${LOCAL_IP}:8888
        description: PDF Tools
        icon: stirling-pdf.png

- AI:
    - Open WebUI:
        href: http://${LOCAL_IP}:3000
        description: Local AI Chat
        icon: ollama.png
EOF"

docker restart homepage
echo -e "${GREEN}Homepage configured${NC}"

# =============================================================
# STEP 8 — PULL AND START ALL SERVICES
# =============================================================

echo -e "\n${YELLOW}[8/9] Pulling and starting all services (this may take a while)...${NC}"
cd ~/homelab && docker compose pull && docker compose up -d

# =============================================================
# STEP 9 — DONE
# =============================================================

echo -e "\n${YELLOW}[9/9] Setup complete!${NC}"
echo ""
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}  🎉 Pi Homelab is ready!${NC}"
echo -e "${GREEN}=================================================${NC}"
echo ""
echo -e "Access your services at:"
echo -e "  ${BLUE}http://${LOCAL_IP}:3005${NC}        — Homepage Dashboard"
echo -e "  ${BLUE}http://${LOCAL_IP}:8123${NC}        — Home Assistant"
echo -e "  ${BLUE}http://${LOCAL_IP}:5678${NC}        — n8n Automation"
echo -e "  ${BLUE}http://${LOCAL_IP}:81${NC}          — Nginx Proxy Manager"
echo -e "  ${BLUE}http://${LOCAL_IP}:8080${NC}        — Vaultwarden"
echo -e "  ${BLUE}http://${LOCAL_IP}:3001${NC}        — Uptime Kuma"
echo -e "  ${BLUE}http://${LOCAL_IP}:8181${NC}        — Nextcloud"
echo -e "  ${BLUE}http://${LOCAL_IP}:8888${NC}        — Stirling PDF"
echo -e "  ${BLUE}http://${LOCAL_IP}:3000${NC}        — Open WebUI (AI)"
echo -e "  ${BLUE}http://${LOCAL_IP}:8053/admin${NC}  — Pi-hole"
echo -e "  ${BLUE}http://${LOCAL_IP}:19999${NC}       — Netdata"
echo -e "  ${BLUE}https://${LOCAL_IP}:9443${NC}       — Portainer"
echo ""
echo -e "${YELLOW}⚠️  Remember to:${NC}"
echo "  1. Change default passwords (Nginx Proxy Manager: admin@example.com / changeme)"
echo "  2. Set up Tailscale for remote access: sudo tailscale up"
echo "  3. Point your router DNS to ${LOCAL_IP} to enable Pi-hole network-wide"
echo "  4. Pull an AI model: docker exec -it ollama ollama pull llama3.2"
echo ""
echo -e "${GREEN}Enjoy your homelab! 🚀${NC}"
