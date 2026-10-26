# Backup and restore — existing Restic tooling

Ansible installs Restic and rclone, as the previous installer did. This change does not
configure a repository, credentials, schedules or retention. The old Bash wrappers have
been removed; no replacement backup service is selected in this baseline.

Git preserves deployment configuration. Back up `/srv/homelab/state` separately, including
Home Assistant's `.storage`, registries and database. The existing include/exclude files
remain under `backup/`.

## Prerequisites

Configure a Restic repository on independent storage, its credentials and a password file
outside Git. If using rclone, configure its remote for the same user that will run Restic.
Keep the repository password and remote credentials somewhere independent of the Pi.
A backup on the same SD card is not disaster recovery.

The commands below use placeholders; replace them with the configured repository and
password-file path. For an rclone backend, run them as the user owning the rclone config.
Make sure that user can read all application state; do not assume the installed packages
or the top-level directory ownership grant access to every file.

Initialize a new repository only once:

```console
restic --repo YOUR_REPOSITORY --password-file YOUR_PASSWORD_FILE init
```

## Consistent backup

From the **existing Compose checkout on the Pi**, stop the applications before copying
active databases. Wait for a clean stop before creating a snapshot:

```console
docker compose stop
restic --repo YOUR_REPOSITORY --password-file YOUR_PASSWORD_FILE backup --files-from backup/includes.txt --exclude-file backup/excludes.txt --tag pi-homelab --tag state
docker compose start
```

If backup fails, restart the applications explicitly after investigating. These are manual
commands, not a scheduler or an automatic stop/start workflow. Retention and pruning remain
to be configured separately.

## Restore safely into staging

Inspect the available snapshots, then restore the selected snapshot to a temporary directory,
not directly over live state:

```console
restic --repo YOUR_REPOSITORY --password-file YOUR_PASSWORD_FILE snapshots
restic --repo YOUR_REPOSITORY --password-file YOUR_PASSWORD_FILE check
restic --repo YOUR_REPOSITORY --password-file YOUR_PASSWORD_FILE restore YOUR_SNAPSHOT_ID --target YOUR_STAGING_DIRECTORY
```

Verify the restored files. On a rebuilt host, run Ansible to recreate the prerequisites,
stop any running applications, preserve the current state, then copy the verified restored
state to `/srv/homelab/state` with its required ownership and permissions. Reuse the Compose
configuration, start the applications and verify their contents.

Automating that final replacement is outside this baseline. A complete recovery must still
be tested on a spare installation; a successful snapshot alone does not prove recovery.
