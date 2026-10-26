# Pi Homelab

Minimal Raspberry Pi 5 homelab foundation for **Ubuntu Server 24.04 LTS ARM64**.
The current change introduces a small Ansible baseline and Docker installation.

## Current scope

Ansible runs from Ubuntu in WSL and connects to the Pi over SSH. It:

1. Checks that the host runs Ubuntu 24.04 on ARM64.
2. Installs the base packages already used by the previous installer, including Restic and rclone.
3. Prepares the existing `/srv/homelab` directory layout without recursively changing application data.
4. Installs and enables Docker Engine and the Compose plugin using
   [geerlingguy.docker](https://github.com/geerlingguy/ansible-role-docker), pinned in `requirements.yml`.
5. Adds the existing SSH user to the Docker group, matching the previous installer.

This baseline does **not** deploy applications, install Tailscale, change SSH settings,
configure a firewall, apply hardening, mount USB storage, upgrade the OS or reboot.
Those changes will be considered separately. No Bash scripts are required or retained.

## Existing application stack

The existing Compose file and Homepage configuration are preserved:

| Service | Definition | Access when manually deployed |
|---|---|---|
| Home Assistant Container | `docker-compose.yml` | HTTP 8123 |
| Homepage | `docker-compose.yml` | HTTP 3005 |

Restic and rclone remain available as host tooling. Their installation does not configure
a backup. Tailscale remains the intended private access solution, but its installation
has not yet been ported to this Ansible baseline.

## Start from WSL

Ubuntu and SSH must already work on the Pi. The user configured in the inventory must
already exist and have sudo rights. Python 3 must be available on the Pi.

In your **WSL terminal**, clone the repository under your Linux home directory:

```console
git clone https://github.com/bvssteel/pi-homelab.git
cd pi-homelab
ansible-galaxy role install -r requirements.yml
cp inventory/hosts.example.yml inventory/hosts.yml
```

Edit `inventory/hosts.yml` with the Pi's address and your existing Ubuntu username.
This local file is ignored by Git. Do not store passwords or private keys in the repository.

Connect once from WSL and verify the Pi's SSH fingerprint:

```console
ssh YOUR_UBUNTU_USER@YOUR_PI_IP
```

Return to WSL with `exit`. If using SSH password authentication, install `sshpass`
in WSL (`sudo apt install sshpass`), then run:

```console
ansible homelab -m ansible.builtin.ping --ask-pass
ansible-playbook site.yml --ask-pass --ask-become-pass
```

If SSH keys already work, omit `--ask-pass`. `--ask-become-pass` asks for the sudo password.
SSH authentication is not changed by the playbook. Log out and reconnect before using
Docker without sudo: Docker group membership grants root-equivalent control of the host.

## Verify

On the Pi:

```console
docker version
docker compose version
```

From WSL, rerun the same playbook to reconcile the host configuration. The Docker role
uses the official Docker package repository. Its role version is pinned; installed Docker
packages follow the repository's available version on first installation. This baseline
does not configure automatic updates or perform a blanket package upgrade.

## Configuration and state

| Path | Purpose |
|---|---|
| WSL checkout | Ansible, inventory and versioned Compose/configuration |
| `/srv/homelab/state/home-assistant` | Existing Home Assistant state |
| `/srv/homelab/backups` | Existing local backup directory |
| `/srv/homelab/logs` | Existing log directory |

Git describes configuration; application state must be backed up separately.
The baseline does not clone this repository onto the Pi or start containers.

## Documentation

- [Host baseline and existing Compose deployment](docs/manual-setup.md)
- [Backup and restore using the existing tools](docs/restore.md)
- [Storage scope](docs/migrate-to-ssd.md)
- [Application decisions](docs/apps.md)

No changes have been applied to the Pi by editing this repository. Syntax and lint checks
can validate the Ansible files; a first run and subsequent rerun on the Pi are still required
before claiming working provisioning and idempotence on hardware.
