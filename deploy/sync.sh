#!/usr/bin/env bash
# Sync this repo (and .env) from the laptop to the London EC2 box.
set -euo pipefail

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DEPLOY_DIR}/.." && pwd)"
STATE_ENV="${DEPLOY_DIR}/.instance.env"

if [[ -f "${STATE_ENV}" ]]; then
  # shellcheck disable=SC1090
  source "${STATE_ENV}"
fi

PUBLIC_IP="${PUBLIC_IP:-${1:-}}"
KEY_PATH="${KEY_PATH:-${2:-}}"
SSH_USER="${SSH_USER:-ubuntu}"
REMOTE_DIR="${REMOTE_DIR:-~/bybit}"

if [[ -z "${PUBLIC_IP}" || -z "${KEY_PATH}" ]]; then
  echo "Usage: ./deploy/sync.sh [PUBLIC_IP] [KEY_PATH]" >&2
  echo "Or run after ./deploy/launch_ec2.sh (reads deploy/.instance.env)." >&2
  exit 1
fi

if [[ ! -f "${KEY_PATH}" ]]; then
  echo "Key not found: ${KEY_PATH}" >&2
  exit 1
fi

SSH_OPTS=(-i "${KEY_PATH}" -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes)

echo "==> Ensuring remote dir ${REMOTE_DIR} on ${SSH_USER}@${PUBLIC_IP}"
ssh "${SSH_OPTS[@]}" "${SSH_USER}@${PUBLIC_IP}" "mkdir -p ${REMOTE_DIR}"

echo "==> rsync project → ${SSH_USER}@${PUBLIC_IP}:${REMOTE_DIR}"
rsync -az --delete \
  --exclude '.git/' \
  --exclude '.venv/' \
  --exclude '__pycache__/' \
  --exclude 'deploy/.launch-state.json' \
  --exclude 'deploy/.instance.env' \
  --exclude '*.pem' \
  -e "ssh -i ${KEY_PATH} -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes" \
  "${ROOT}/" \
  "${SSH_USER}@${PUBLIC_IP}:${REMOTE_DIR}/"

if [[ -f "${ROOT}/.env" ]]; then
  echo "==> Copying .env (secrets) over SCP"
  scp "${SSH_OPTS[@]}" "${ROOT}/.env" "${SSH_USER}@${PUBLIC_IP}:${REMOTE_DIR}/.env"
else
  echo "==> No local .env yet — copy .env.example on the box or create one before auth smokes."
fi

echo "Sync complete."
echo "  ssh -i ${KEY_PATH} ${SSH_USER}@${PUBLIC_IP}"
echo "  cd ${REMOTE_DIR} && bash deploy/bootstrap.sh"
