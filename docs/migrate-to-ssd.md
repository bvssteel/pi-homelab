# Storage scope

This baseline targets Ubuntu Server 24.04 ARM64 running from the existing microSD.
Ansible creates the existing `/srv/homelab` directory layout but does not partition, format,
mount or migrate any disk. It does not recursively change ownership of application data.

USB media storage and an eventual SSD system disk will be separate changes after their
layout and mounting behavior are agreed. The previous Raspberry Pi OS guide using
`rpi-clone` and `raspi-config` does not establish a tested Ubuntu migration procedure
and has been removed.

Before a future migration, keep an independent backup of application state, credentials
and local configuration. Rebuilding Ubuntu and rerunning Ansible restores prerequisites;
it does not by itself restore application data.
