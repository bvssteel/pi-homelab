#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="${REPO_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
RESTIC_ENV="${RESTIC_ENV:-/etc/pi-homelab/restic.env}"

if [ ! -f "${RESTIC_ENV}" ]; then
  cat >&2 <<EOF
Missing ${RESTIC_ENV}

Create it with at least:
  export RESTIC_REPOSITORY='rclone:remote:path/to/pi-homelab'
  export RESTIC_PASSWORD='change-me-or-use-password-file'

Optional:
  export RESTIC_PASSWORD_FILE='/path/to/password-file'
EOF
  exit 1
fi

# shellcheck disable=SC1090
source "${RESTIC_ENV}"

cd "${REPO_DIR}"
restic backup \
  --files-from backup/includes.txt \
  --exclude-file backup/excludes.txt \
  --tag pi-homelab \
  --tag state

restic forget \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 12 \
  --prune

restic check
