# Manual Setup Guide

If you prefer to set up your Pi homelab step by step manually rather than using the automated script, follow this guide.

---

## Prerequisites

- Raspberry Pi 5 flashed with Raspberry Pi OS (64-bit)
- SSH access to your Pi
- Internet connection

---

## Step 1 — Update System

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git nano htop
```

---

## Step 2 — Install Docker

```bash
curl -sSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

Log out and back in, then verify:

```bash
docker ps
```

Fix IPv6 issues (common on Pi):

```bash
sudo nano /etc/docker/daemon.json
```

Add:

```json
{
  "ipv6": false,
  "ip": "0.0.0.0"
}
```

```bash
sudo systemctl restart docker
```

---

## Step 3 — Install Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Follow the URL to authenticate. Install Tailscale on your other devices from [tailscale.com/download](https://tailscale.com/download).

---

## Step 4 — Install Netdata

```bash
curl https://get.netdata.cloud/kickstart.sh > /tmp/netdata-kickstart.sh
sudo sh /tmp/netdata-kickstart.sh
```

Access at `http://YOUR_PI_IP:19999`

---

## Step 5 — Create Docker Stack

```bash
mkdir ~/homelab
cd ~/homelab
nano docker-compose.yml
```

Paste the contents of `docker-compose.yml` from this repo, replacing `YOUR_PI_IP` with your actual IP and updating any passwords.

---

## Step 6 — Start Services

```bash
cd ~/homelab && docker compose up -d
```

---

## Step 7 — Configure Homepage

```bash
docker exec -it homepage sh
```

Then paste your services.yaml content.

---

## Step 8 — Configure Pi-hole Network Wide

1. Log into your router admin page
2. Find DNS settings (under LAN or DHCP)
3. Set Primary DNS to your Pi's IP address
4. All devices on your network will use Pi-hole automatically

---

## Step 9 — Pull an AI Model

```bash
docker exec -it ollama ollama pull llama3.2
```

Then access Open WebUI at `http://YOUR_PI_IP:3000`

---

## Useful Commands

```bash
# View all containers
docker ps

# View logs
docker logs <container-name> --tail 50

# Restart a service
docker restart <container-name>

# Update all services
cd ~/homelab && docker compose pull && docker compose up -d

# Check Tailscale status
tailscale status

# Check disk usage
df -h

# Check system resources
htop
```
