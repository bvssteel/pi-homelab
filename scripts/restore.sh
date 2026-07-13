#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="${REPO_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
RESTIC_ENV="${RESTIC_ENV:-/etc/pi-homelab/restic.env}"
SNAPSHOT="${1:-latest}"

if [ ! -f "${RESTIC_ENV}" ]; then
  echo "Missing ${RESTIC_ENV}" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "${RESTIC_ENV}"

cd "${REPO_DIR}"

echo "Stopping stack before restore..."
docker compose --env-file .env down || true

echo "Restoring snapshot ${SNAPSHOT} into /"
sudo restic restore "${SNAPSHOT}" --target /

echo "Starting stack..."
docker compose --env-file .env up -d --remove-orphans
