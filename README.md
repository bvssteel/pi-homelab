# Pi Homelab

Minimal Raspberry Pi 5 homelab foundation focused on resilience, restoreability, and low-maintenance operations.

This repository is no longer a catalogue of self-hosted apps. It is the **v0 operating base** for the homelab:

- Docker Compose for the minimal application stack.
- Tailscale for private remote access.
- Homepage as the entry dashboard.
- Home Assistant as the first real service.
- Restic/rclone installed on the host for future state backups.
- Clear `/srv/homelab` paths so state can be backed up and restored.

## Philosophy

```text
Git = source of truth for deployable configuration
/srv/homelab/state = application state that cannot fully live in Git
Backups = encrypted copy of non-declarative state
The running host = replaceable instance
```

The goal is not to make the Raspberry Pi immortal. The goal is to make it easy to rebuild.

## v0 stack

| Component | Role | Status |
|---|---|---|
| Docker / Compose | Container runtime | v0 |
| Tailscale | Private remote access | v0 |
| Home Assistant | Smart home hub | v0 |
| Homepage | Homelab dashboard | v0 |
| Restic + rclone | Backup/restore tooling | v0 host tooling |

Intentionally excluded from v0: Portainer, Watchtower, Caddy, Traefik, Pi-hole, AdGuard Home, Uptime Kuma, Semaphore, Nextcloud, n8n, Vaultwarden, Ollama, Open WebUI, Stirling PDF, and Netdata.

See [`docs/apps.md`](docs/apps.md) for the decision log.

## Filesystem layout

```text
/opt/pi-homelab
└── Git checkout of this repository

/srv/homelab
├── state/
│   └── home-assistant/
├── backups/
└── logs/
```

## Quick start

Flash Raspberry Pi OS Lite 64-bit, enable SSH, then run:

```bash
curl -fsSL https://raw.githubusercontent.com/bvssteel/pi-homelab/main/setup.sh | bash
```

To test the v0 branch before merging it:

```bash
curl -fsSL https://raw.githubusercontent.com/bvssteel/pi-homelab/v0-minimal-stack/setup.sh | REPO_BRANCH=v0-minimal-stack bash
```

The bootstrap script will:

1. Install base packages.
2. Install Docker if missing.
3. Install and start Tailscale.
4. Prepare `/srv/homelab` directories.
5. Clone or update this repo in `/opt/pi-homelab`.
6. Generate `/opt/pi-homelab/.env` if missing.
7. Deploy the Docker Compose stack.

## Access

After deployment:

```text
Homepage:       http://<pi-ip>:3005
Home Assistant: http://<pi-ip>:8123
```

Home Assistant uses host networking for discovery-friendly smart home behavior.

Homepage is published on port `3005` and uses the versioned config in `config/homepage`.

## Day-to-day operations

Deploy the current Git state:

```bash
cd /opt/pi-homelab
./scripts/deploy.sh
```

Run a backup once Restic is configured:

```bash
cd /opt/pi-homelab
./scripts/backup.sh
```

Restore the latest backup:

```bash
cd /opt/pi-homelab
./scripts/restore.sh latest
```

See [`docs/restore.md`](docs/restore.md) for backup prerequisites and recovery notes.

## Configuration and state model

Declarative configuration belongs in Git:

```text
docker-compose.yml
config/homepage/*.yaml
scripts/*.sh
docs/*.md
backup/*.txt
```

Non-declarative state belongs under `/srv/homelab/state` and must be backed up:

```text
/srv/homelab/state/home-assistant
```

Home Assistant declarative YAML will eventually live in a separate repository. This repo only owns the deployment contract and state mount point.

## Update policy

v0 intentionally does **not** use Watchtower.

The future direction is:

```text
Renovate updates Git
Git describes the desired version
The Pi deploys what Git declares
```

For now, images use simple stable/latest channels:

```text
ghcr.io/home-assistant/home-assistant:stable
ghcr.io/gethomepage/homepage:latest
```

## Next milestones

- Add a separate Home Assistant config repository.
- Add Restic repository configuration and a first restore test.
- Add Renovate for controlled image updates.
- Decide whether Uptime Kuma, Pi-hole/AdGuard, Portainer, Semaphore, or Caddy belong in v1.
