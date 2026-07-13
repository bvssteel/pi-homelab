# Application decisions

This document tracks the application scope for the homelab. The v0 goal is to establish a resilient base, not to run every possible service.

## v0

| Application | Status | Role | Exposure | State path | Notes |
|---|---|---|---|---|---|
| Docker Compose | v0 | Container orchestration | Host only | n/a | Deployment primitive. |
| Tailscale | v0 | Private remote access | Tailnet | Host state | No public port forwarding required. |
| Home Assistant | v0 | Smart home hub | LAN + Tailscale | `/srv/homelab/state/home-assistant` | Config repo will be separate later. |
| Homepage | v0 | Dashboard | LAN + Tailscale | Git config | Config lives in `config/homepage`. |
| Restic | v0 tooling | Backup and restore | Host only | n/a | Not a visible app; used for state snapshots. |

## Later candidates

| Application | Status | Why not v0? |
|---|---|---|
| Uptime Kuma | later | Useful, but v0 can start without an extra stateful service. |
| Pi-hole / AdGuard Home | later | DNS services are useful but become network-critical. Add after the base is stable. |
| Portainer | later | Nice UI, but Git + Compose should remain the source of truth. |
| Semaphore | later | Useful once Ansible roles become real. |
| Caddy | later | Useful for clean local URLs; not necessary with LAN + Tailscale access. |
| Traefik | rejected for now | Powerful, but too much complexity for a single-host v0. |

## Explicitly removed from the fork

| Application | Decision |
|---|---|
| n8n | Not needed for v0. |
| Nextcloud | Not wanted. |
| Ollama | Not wanted on the Pi. |
| Open WebUI | Not wanted without Ollama. |
| Vaultwarden | Sensitive service; not needed for v0. |
| Nginx Proxy Manager | Replaced by no reverse proxy for v0. |
| Watchtower | Avoids silent drift outside Git. Renovate will be preferred later. |
| Stirling PDF | Not needed for v0. |
| Netdata | Not needed for v0. |
