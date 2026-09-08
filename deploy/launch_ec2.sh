#!/usr/bin/env bash
# Launch a Free Tier–eligible Ubuntu EC2 in eu-west-2 (London) for testnet API testing.
# Prerequisites: AWS CLI v2 configured with EC2 permissions.
set -euo pipefail

REGION="${AWS_REGION:-eu-west-2}"
NAME_PREFIX="${NAME_PREFIX:-bybit-testnet}"
KEY_NAME="${KEY_NAME:-${NAME_PREFIX}-key}"
SG_NAME="${SG_NAME:-${NAME_PREFIX}-ssh}"
INSTANCE_TYPE="${INSTANCE_TYPE:-t3.micro}"
VOLUME_GIB="${VOLUME_GIB:-8}"
STATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="${STATE_DIR}/.launch-state.json"
KEY_PATH="${KEY_PATH:-$HOME/.ssh/${KEY_NAME}.pem}"

echo "==> Region: ${REGION}"
echo "==> Instance type: ${INSTANCE_TYPE} (override with INSTANCE_TYPE= if Free Tier differs)"

# Resolve Ubuntu 24.04 AMI owned by Canonical (free-tier eligible AMIs vary by account).
AMI_ID="$(
  aws ec2 describe-images \
    --region "${REGION}" \
    --owners 099720109477 \
    --filters \
      "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" \
      "Name=state,Values=available" \
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
    --output text
)"
if [[ -z "${AMI_ID}" || "${AMI_ID}" == "None" ]]; then
  AMI_ID="$(
    aws ec2 describe-images \
      --region "${REGION}" \
      --owners 099720109477 \
      --filters \
        "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*" \
        "Name=state,Values=available" \
      --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
      --output text
  )"
fi
echo "==> AMI: ${AMI_ID}"

MY_IP="$(curl -4 -fsS https://checkip.amazonaws.com | tr -d '[:space:]')"
if [[ -z "${MY_IP}" ]]; then
  echo "Could not detect your public IP for SSH lockdown." >&2
  exit 1
fi
echo "==> SSH allow from ${MY_IP}/32"

# Default VPC
VPC_ID="$(
  aws ec2 describe-vpcs \
    --region "${REGION}" \
    --filters Name=isDefault,Values=true \
    --query 'Vpcs[0].VpcId' \
    --output text
)"
if [[ -z "${VPC_ID}" || "${VPC_ID}" == "None" ]]; then
  echo "No default VPC in ${REGION}. Create a VPC or set VPC_ID." >&2
  exit 1
fi

# Security group (reuse if present)
SG_ID="$(
  aws ec2 describe-security-groups \
    --region "${REGION}" \
    --filters "Name=group-name,Values=${SG_NAME}" "Name=vpc-id,Values=${VPC_ID}" \
    --query 'SecurityGroups[0].GroupId' \
    --output text 2>/dev/null || true
)"
if [[ -z "${SG_ID}" || "${SG_ID}" == "None" ]]; then
  SG_ID="$(
    aws ec2 create-security-group \
      --region "${REGION}" \
      --group-name "${SG_NAME}" \
      --description "SSH only for ${NAME_PREFIX} testnet box" \
      --vpc-id "${VPC_ID}" \
      --query 'GroupId' \
      --output text
  )"
  aws ec2 authorize-security-group-ingress \
    --region "${REGION}" \
    --group-id "${SG_ID}" \
    --protocol tcp \
    --port 22 \
    --cidr "${MY_IP}/32" >/dev/null
  echo "==> Created security group ${SG_ID}"
else
  echo "==> Reusing security group ${SG_ID}"
  # Ensure current IP is allowed (idempotent-ish: ignore Duplicate error)
  aws ec2 authorize-security-group-ingress \
    --region "${REGION}" \
    --group-id "${SG_ID}" \
    --protocol tcp \
    --port 22 \
    --cidr "${MY_IP}/32" >/dev/null 2>&1 || true
fi

# Key pair
if [[ ! -f "${KEY_PATH}" ]]; then
  mkdir -p "$(dirname "${KEY_PATH}")"
  if aws ec2 describe-key-pairs --region "${REGION}" --key-names "${KEY_NAME}" >/dev/null 2>&1; then
    echo "Key pair ${KEY_NAME} exists in AWS but ${KEY_PATH} is missing locally." >&2
    echo "Delete the AWS key pair or set KEY_NAME / KEY_PATH to a new name." >&2
    exit 1
  fi
  aws ec2 create-key-pair \
    --region "${REGION}" \
    --key-name "${KEY_NAME}" \
    --query 'KeyMaterial' \
    --output text > "${KEY_PATH}"
  chmod 400 "${KEY_PATH}"
  echo "==> Created key pair → ${KEY_PATH}"
else
  echo "==> Using existing key ${KEY_PATH}"
  if ! aws ec2 describe-key-pairs --region "${REGION}" --key-names "${KEY_NAME}" >/dev/null 2>&1; then
    echo "Local key exists but AWS key pair ${KEY_NAME} is missing. Import or recreate." >&2
    exit 1
  fi
fi

SUBNET_ID="$(
  aws ec2 describe-subnets \
    --region "${REGION}" \
    --filters "Name=vpc-id,Values=${VPC_ID}" "Name=default-for-az,Values=true" \
    --query 'Subnets[0].SubnetId' \
    --output text
)"

INSTANCE_ID="$(
  aws ec2 run-instances \
    --region "${REGION}" \
    --image-id "${AMI_ID}" \
    --instance-type "${INSTANCE_TYPE}" \
    --key-name "${KEY_NAME}" \
    --security-group-ids "${SG_ID}" \
    --subnet-id "${SUBNET_ID}" \
    --associate-public-ip-address \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":${VOLUME_GIB},\"VolumeType\":\"gp3\",\"DeleteOnTermination\":true}}]" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${NAME_PREFIX}}]" \
    --query 'Instances[0].InstanceId' \
    --output text
)"
echo "==> Launched ${INSTANCE_ID}; waiting for running..."
aws ec2 wait instance-running --region "${REGION}" --instance-ids "${INSTANCE_ID}"
aws ec2 wait instance-status-ok --region "${REGION}" --instance-ids "${INSTANCE_ID}" 2>/dev/null || true

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

cat > "${STATE_FILE}" <<EOF
{
  "region": "${REGION}",
  "instance_id": "${INSTANCE_ID}",
  "public_ip": "${PUBLIC_IP}",
  "public_dns": "${PUBLIC_DNS}",
  "key_path": "${KEY_PATH}",
  "key_name": "${KEY_NAME}",
  "security_group_id": "${SG_ID}",
  "security_group_name": "${SG_NAME}"
}
EOF

# Machine-readable env for sync/teardown
cat > "${STATE_DIR}/.instance.env" <<EOF
AWS_REGION=${REGION}
INSTANCE_ID=${INSTANCE_ID}
PUBLIC_IP=${PUBLIC_IP}
PUBLIC_DNS=${PUBLIC_DNS}
KEY_PATH=${KEY_PATH}
KEY_NAME=${KEY_NAME}
SG_ID=${SG_ID}
SSH_USER=ubuntu
EOF

echo
echo "=== Launch complete ==="
echo "Instance: ${INSTANCE_ID}"
echo "Public IP: ${PUBLIC_IP}"
echo "SSH: ssh -i ${KEY_PATH} ubuntu@${PUBLIC_IP}"
echo "State: ${STATE_FILE}"
echo
echo "Next:"
echo "  1) ./deploy/sync.sh"
echo "  2) ssh -i ${KEY_PATH} ubuntu@${PUBLIC_IP}"
echo "  3) cd ~/bybit && bash deploy/bootstrap.sh"
echo "  4) source .venv/bin/activate && python scripts/check_egress_ip.py"
echo "  5) python scripts/smoke_bybit.py"
