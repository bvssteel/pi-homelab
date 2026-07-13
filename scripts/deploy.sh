#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="${REPO_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "${REPO_DIR}"

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .env from .env.example. Review it if hostname/IP access fails."
fi

docker compose --env-file .env config --quiet
docker compose --env-file .env pull
docker compose --env-file .env up -d --remove-orphans

docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
