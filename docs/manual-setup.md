# Ubuntu baseline and existing application stack

## Host preparation

Use the Ansible instructions in the README from WSL. The target is Ubuntu Server 24.04
ARM64, already installed with SSH and a sudo user. Existing package updates performed
before reboot do not need to be repeated.

`site.yml` prepares the host and installs Docker/Compose. It preserves SSH authentication
and does not configure hardening, a firewall, networking, Tailscale or application deployment.
The package list and existing directory layout are in `inventory/group_vars/homelab.yml`.

## Optional: manually run the existing Compose stack

This remains a separate operation. Do it only when ready to run the existing Home Assistant
and Homepage services. On the Pi, use an existing checkout or clone the repository into your
home directory; the new host baseline does not create a checkout in `/opt`.

```console
git clone https://github.com/bvssteel/pi-homelab.git
cd pi-homelab
cp .env.example .env
```

Review `.env`, especially `HOMEPAGE_ALLOWED_HOSTS`, and add the exact hostname/IP and port
you will use. Review the existing Compose mounts and published ports before starting it.
The Compose file is unchanged by this baseline, including its current Docker socket mount.

```console
docker compose config --quiet
docker compose pull
docker compose up -d
```

Existing installations should reuse their current checkout/project rather than start a
second copy on the same ports. No migration or renaming of the existing stack is performed.
Configuration changes belong in Git; the baseline itself does not execute these commands.

## Checks

```console
docker version
docker compose version
docker compose ps
```

Tailscale installation and the automatic Compose deployment will be separate changes.
The old Bash installer and deployment scripts have been removed.
