#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="${REPO_URL:-https://github.com/bvssteel/pi-homelab.git}"
REPO_DIR="${REPO_DIR:-/opt/pi-homelab}"

info() { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok() { printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }

resolve_repo_branch() {
  if [ -n "${REPO_BRANCH:-}" ]; then
    printf '%s\n' "${REPO_BRANCH}"
    return
  fi

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
ADMIN_USER="${SUDO_USER:-${USER}}"

install_bootstrap_dependencies() {
  info "Installing Git and Ansible bootstrap dependencies"
  sudo apt-get update
  sudo apt-get install -y ca-certificates git ansible
}

checkout_repo() {
  info "Synchronizing ${REPO_URL} branch ${REPO_BRANCH} into ${REPO_DIR}"

  sudo mkdir -p "$(dirname "${REPO_DIR}")"
  sudo chown "${ADMIN_USER}:${ADMIN_USER}" "$(dirname "${REPO_DIR}")"

  if [ -d "${REPO_DIR}/.git" ]; then
    git -C "${REPO_DIR}" fetch origin "${REPO_BRANCH}"
    git -C "${REPO_DIR}" checkout -B "${REPO_BRANCH}" "origin/${REPO_BRANCH}"
    git -C "${REPO_DIR}" reset --hard "origin/${REPO_BRANCH}"
  else
    git clone --branch "${REPO_BRANCH}" "${REPO_URL}" "${REPO_DIR}"
  fi
}

apply_ansible() {
  info "Applying Ansible configuration from branch ${REPO_BRANCH}"
  cd "${REPO_DIR}"

  sudo ansible-playbook \
    --inventory ansible/inventory/localhost.yml \
    ansible/site.yml \
    --extra-vars "homelab_repo_branch=${REPO_BRANCH} homelab_admin_user=${ADMIN_USER}"
}

main() {
  install_bootstrap_dependencies
  checkout_repo
  apply_ansible

  ok "Homelab host configuration applied"
  echo "Repository: ${REPO_DIR}"
  echo "Branch:     ${REPO_BRANCH}"
  echo "User:       ${ADMIN_USER}"
}

main "$@"
