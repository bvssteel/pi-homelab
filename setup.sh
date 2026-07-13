#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="${REPO_URL:-https://github.com/bvssteel/pi-homelab.git}"
REPO_DIR="${REPO_DIR:-/opt/pi-homelab}"
STATE_DIR="${STATE_DIR:-/srv/homelab/state}"
BACKUP_DIR="${BACKUP_DIR:-/srv/homelab/backups}"
LOG_DIR="${LOG_DIR:-/srv/homelab/logs}"
DEFAULT_TZ="${TZ:-Europe/Paris}"

info() { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok() { printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }

resolve_repo_branch() {
  if [ -n "${REPO_BRANCH:-}" ]; then
    printf '%s\n' "${REPO_BRANCH}"
    return
  fi

  # When setup.sh is executed from a local checkout, keep that branch instead of
  # forcing main. This makes PR branch tests behave as expected.
  local script_dir
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P || true)"

  if [ -n "${script_dir}" ] && git -C "${script_dir}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local current_branch
    current_branch="$(git -C "${script_dir}" branch --show-current 2>/dev/null || true)"
    if [ -n "${current_branch}" ]; then
      printf '%s\n' "${current_branch}"
      return
    fi
  fi

  printf 'main\n'
}

REPO_BRANCH="$(resolve_repo_branch)"

install_base_packages() {
  info "Installing base packages"
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl git gnupg htop jq nano restic rclone
}

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    ok "Docker already installed"
    return
  fi

  info "Installing Docker"
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "${USER}"
  ok "Docker installed. Log out/in later to use docker without sudo."
}

install_tailscale() {
  if command -v tailscale >/dev/null 2>&1; then
    ok "Tailscale already installed"
  else
    info "Installing Tailscale"
    curl -fsSL https://tailscale.com/install.sh | sh
  fi

  if ! sudo tailscale status >/dev/null 2>&1; then
    warn "Tailscale is not authenticated yet. Opening auth flow."
    sudo tailscale up
  else
    ok "Tailscale is running"
  fi
}

prepare_directories() {
  info "Creating homelab directories"
  sudo mkdir -p \
    "${STATE_DIR}/home-assistant" \
    "${BACKUP_DIR}" \
    "${LOG_DIR}"
  sudo chown -R "${USER}:${USER}" /srv/homelab
}

checkout_repo() {
  info "Preparing repository in ${REPO_DIR}"
  info "Using repository branch: ${REPO_BRANCH}"

  if [ -d "${REPO_DIR}/.git" ]; then
    git -C "${REPO_DIR}" fetch origin "${REPO_BRANCH}"
    git -C "${REPO_DIR}" checkout -B "${REPO_BRANCH}" "origin/${REPO_BRANCH}"
    git -C "${REPO_DIR}" pull --ff-only origin "${REPO_BRANCH}"
  else
    sudo mkdir -p "$(dirname "${REPO_DIR}")"
    sudo chown -R "${USER}:${USER}" "$(dirname "${REPO_DIR}")"
    git clone --branch "${REPO_BRANCH}" "${REPO_URL}" "${REPO_DIR}"
  fi
}

write_env_file() {
  local local_ip
  local host_name
  local_ip="$(hostname -I | awk '{print $1}')"
  host_name="$(hostname -s)"

  if [ -f "${REPO_DIR}/.env" ]; then
    ok "Keeping existing ${REPO_DIR}/.env"
    return
  fi

  info "Writing default .env"
  cat > "${REPO_DIR}/.env" <<EOF
TZ=${DEFAULT_TZ}
HOMEPAGE_ALLOWED_HOSTS=${host_name}.local:3005,${local_ip}:3005,localhost:3005,127.0.0.1:3005
EOF
}

deploy_stack() {
  info "Deploying minimal Docker stack"
  cd "${REPO_DIR}"
  sudo docker compose --env-file .env config --quiet
  sudo docker compose --env-file .env pull
  sudo docker compose --env-file .env up -d --remove-orphans
  sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
}

main() {
  install_base_packages
  install_docker
  install_tailscale
  prepare_directories
  checkout_repo
  write_env_file
  deploy_stack

  ok "Minimal homelab v0 is ready"
  echo ""
  echo "Homepage:       http://$(hostname -I | awk '{print $1}'):3005"
  echo "Home Assistant: http://$(hostname -I | awk '{print $1}'):8123"
  echo "Repo:           ${REPO_DIR}"
  echo "Branch:         ${REPO_BRANCH}"
  echo "State:          ${STATE_DIR}"
}

main "$@"
