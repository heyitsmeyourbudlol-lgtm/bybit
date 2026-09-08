#!/usr/bin/env bash
# Run ON the EC2 instance after sync/clone: apt deps, venv, pip install.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

echo "==> Updating apt and installing Python tooling"
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  python3 \
  python3-venv \
  python3-pip \
  git \
  curl

echo "==> Creating venv at ${ROOT}/.venv"
python3 -m venv "${ROOT}/.venv"
# shellcheck disable=SC1091
source "${ROOT}/.venv/bin/activate"
python -m pip install --upgrade pip
pip install -r "${ROOT}/requirements.txt"

if [[ ! -f "${ROOT}/.env" ]]; then
  if [[ -f "${ROOT}/.env.example" ]]; then
    cp "${ROOT}/.env.example" "${ROOT}/.env"
    echo "==> Created .env from .env.example — fill in API keys before auth smokes."
  fi
fi

echo
echo "Bootstrap done. Activate and run:"
echo "  source ${ROOT}/.venv/bin/activate"
echo "  python scripts/check_egress_ip.py"
echo "  python scripts/smoke_bybit.py"
echo "  python scripts/smoke_binance.py"
