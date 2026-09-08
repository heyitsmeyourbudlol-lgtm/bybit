#!/usr/bin/env bash
# Stop or terminate the testnet EC2 box; optional SG/key cleanup.
# Usage:
#   ./deploy/teardown.sh          # terminate instance (keeps key + SG)
#   ./deploy/teardown.sh stop     # stop only (saves Free Tier hours)
#   ./deploy/teardown.sh destroy  # terminate + delete SG + AWS key pair (not local .pem)
set -euo pipefail

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_ENV="${DEPLOY_DIR}/.instance.env"
MODE="${1:-terminate}"

if [[ ! -f "${STATE_ENV}" ]]; then
  echo "Missing ${STATE_ENV}. Pass INSTANCE_ID and AWS_REGION env vars, or launch first." >&2
  if [[ -z "${INSTANCE_ID:-}" || -z "${AWS_REGION:-}" ]]; then
    exit 1
  fi
else
  # shellcheck disable=SC1090
  source "${STATE_ENV}"
fi

REGION="${AWS_REGION:-eu-west-2}"

case "${MODE}" in
  stop)
    echo "==> Stopping ${INSTANCE_ID} in ${REGION}"
    aws ec2 stop-instances --region "${REGION}" --instance-ids "${INSTANCE_ID}" >/dev/null
    aws ec2 wait instance-stopped --region "${REGION}" --instance-ids "${INSTANCE_ID}"
    echo "Stopped. Start later with:"
    echo "  aws ec2 start-instances --region ${REGION} --instance-ids ${INSTANCE_ID}"
    echo "  (then refresh public IP in deploy/.instance.env)"
    ;;
  start)
    echo "==> Starting ${INSTANCE_ID} in ${REGION}"
    aws ec2 start-instances --region "${REGION}" --instance-ids "${INSTANCE_ID}" >/dev/null
    aws ec2 wait instance-running --region "${REGION}" --instance-ids "${INSTANCE_ID}"
    PUBLIC_IP="$(
      aws ec2 describe-instances \
        --region "${REGION}" \
        --instance-ids "${INSTANCE_ID}" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text
    )"
    PUBLIC_DNS="$(
      aws ec2 describe-instances \
        --region "${REGION}" \
        --instance-ids "${INSTANCE_ID}" \
        --query 'Reservations[0].Instances[0].PublicDnsName' \
        --output text
    )"
    # Refresh state file fields
    if [[ -f "${STATE_ENV}" ]]; then
      tmp="$(mktemp)"
      while IFS= read -r line; do
        case "${line}" in
          PUBLIC_IP=*) echo "PUBLIC_IP=${PUBLIC_IP}" ;;
          PUBLIC_DNS=*) echo "PUBLIC_DNS=${PUBLIC_DNS}" ;;
          *) echo "${line}" ;;
        esac
      done < "${STATE_ENV}" > "${tmp}"
      mv "${tmp}" "${STATE_ENV}"
    fi
    echo "Started. Public IP: ${PUBLIC_IP}"
    echo "SSH: ssh -i ${KEY_PATH:-~/.ssh/bybit-testnet-key.pem} ubuntu@${PUBLIC_IP}"
    ;;
  terminate|destroy)
    echo "==> Terminating ${INSTANCE_ID} in ${REGION}"
    aws ec2 terminate-instances --region "${REGION}" --instance-ids "${INSTANCE_ID}" >/dev/null
    aws ec2 wait instance-terminated --region "${REGION}" --instance-ids "${INSTANCE_ID}" || true
    echo "Terminated ${INSTANCE_ID}"

    if [[ "${MODE}" == "destroy" ]]; then
      if [[ -n "${SG_ID:-}" ]]; then
        echo "==> Deleting security group ${SG_ID}"
        # May fail briefly if ENI not released; retry once.
        sleep 5
        aws ec2 delete-security-group --region "${REGION}" --group-id "${SG_ID}" || \
          { sleep 15; aws ec2 delete-security-group --region "${REGION}" --group-id "${SG_ID}"; }
      fi
      if [[ -n "${KEY_NAME:-}" ]]; then
        echo "==> Deleting AWS key pair ${KEY_NAME} (local .pem left untouched)"
        aws ec2 delete-key-pair --region "${REGION}" --key-name "${KEY_NAME}" || true
      fi
    fi
    ;;
  *)
    echo "Unknown mode: ${MODE} (use stop|start|terminate|destroy)" >&2
    exit 1
    ;;
esac
