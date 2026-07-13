# Backup and restore

The homelab is split into two categories:

```text
Git
└── declarative configuration

Restic backup
└── non-declarative application state
```

## What Git restores

Git restores:

- Docker Compose definitions.
- Homepage configuration.
- Deployment scripts.
- Backup policies.
- Documentation.

## What Restic restores

Restic restores state that cannot reliably live in Git:

```text
/srv/homelab/state
└── home-assistant
```

For Home Assistant, this includes `.storage`, entity registries, integration state, and local runtime files.

## Restic configuration

Create `/etc/pi-homelab/restic.env` on the host:

```bash
sudo mkdir -p /etc/pi-homelab
sudo nano /etc/pi-homelab/restic.env
```

Example:

```bash
export RESTIC_REPOSITORY='rclone:onedrive:backups/pi-homelab'
export RESTIC_PASSWORD_FILE='/etc/pi-homelab/restic-password'
```

Then store the password:

```bash
sudo nano /etc/pi-homelab/restic-password
sudo chmod 600 /etc/pi-homelab/restic-password /etc/pi-homelab/restic.env
```

Initialize the repository once:

```bash
source /etc/pi-homelab/restic.env
restic init
```

## Backup

```bash
cd /opt/pi-homelab
./scripts/backup.sh
```

The include and exclude policies live in:

```text
backup/includes.txt
backup/excludes.txt
```

## Restore

From a fresh host:

```bash
curl -fsSL https://raw.githubusercontent.com/bvssteel/pi-homelab/main/setup.sh | bash
```

Configure `/etc/pi-homelab/restic.env`, then run:

```bash
cd /opt/pi-homelab
./scripts/restore.sh latest
```

## Recovery principle

A successful backup is not enough. The restore path must be tested periodically on a spare disk or temporary directory.
