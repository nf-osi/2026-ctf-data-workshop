#!/bin/bash
# Builds the workshop AMI end-to-end:
#   1. Launches a temporary Ubuntu 24.04 EC2
#   2. Copies and runs bootstrap.sh on it
#   3. Creates an AMI
#   4. Terminates the temp instance and cleans up
#   5. Updates AMI_ID in test-launch.sh and launch.sh
#
# Usage:
#   export AWS_PROFILE=your-profile
#   bash build-ami.sh

set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
PROFILE_ARGS=()
[[ -n "${AWS_PROFILE:-}" ]] && PROFILE_ARGS=(--profile "$AWS_PROFILE")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AMI_NAME="nf-workshop-2026-$(date +%Y%m%d-%H%M)"
TEMP_KEY_NAME="nf-workshop-bootstrap-$$"
TEMP_KEY_FILE="/tmp/${TEMP_KEY_NAME}.pem"
TEMP_SG_NAME="nf-workshop-bootstrap-$$"
INSTANCE_ID=""
TEMP_SG_ID=""

# ── Cleanup on exit ───────────────────────────────────────────────────────────

cleanup() {
  echo ""
  echo "--- Cleaning up temporary resources ---"
  if [[ -n "$INSTANCE_ID" ]]; then
    echo "Terminating $INSTANCE_ID..."
    aws ec2 terminate-instances --region "$AWS_REGION" "${PROFILE_ARGS[@]}" \
      --instance-ids "$INSTANCE_ID" --output text > /dev/null 2>&1 || true
    aws ec2 wait instance-terminated --region "$AWS_REGION" "${PROFILE_ARGS[@]}" \
      --instance-ids "$INSTANCE_ID" 2>/dev/null || true
  fi
  if [[ -n "$TEMP_SG_ID" ]]; then
    echo "Deleting temp security group $TEMP_SG_ID..."
    aws ec2 delete-security-group --region "$AWS_REGION" "${PROFILE_ARGS[@]}" \
      --group-id "$TEMP_SG_ID" 2>/dev/null || true
  fi
  aws ec2 delete-key-pair --region "$AWS_REGION" "${PROFILE_ARGS[@]}" \
    --key-name "$TEMP_KEY_NAME" > /dev/null 2>&1 || true
  rm -f "$TEMP_KEY_FILE"
}

trap cleanup EXIT

# ── Find latest Ubuntu 24.04 LTS AMI ─────────────────────────────────────────

echo "--- Finding latest Ubuntu 24.04 LTS AMI ---"
BASE_AMI=$(aws ec2 describe-images \
  --region "$AWS_REGION" \
  "${PROFILE_ARGS[@]}" \
  --owners 099720109477 \
  --filters \
    "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" \
    "Name=state,Values=available" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --output text)
echo "Base AMI: $BASE_AMI"

# ── Create temporary key pair ─────────────────────────────────────────────────

echo "--- Creating temporary key pair ---"
aws ec2 create-key-pair \
  --region "$AWS_REGION" \
  "${PROFILE_ARGS[@]}" \
  --key-name "$TEMP_KEY_NAME" \
  --query 'KeyMaterial' \
  --output text > "$TEMP_KEY_FILE"
chmod 600 "$TEMP_KEY_FILE"

# ── Create temporary security group (SSH only) ────────────────────────────────

echo "--- Creating temporary security group ---"
VPC_ID=$(aws ec2 describe-vpcs \
  --region "$AWS_REGION" \
  "${PROFILE_ARGS[@]}" \
  --filters Name=isDefault,Values=true \
  --query 'Vpcs[0].VpcId' \
  --output text)

TEMP_SG_ID=$(aws ec2 create-security-group \
  --region "$AWS_REGION" \
  "${PROFILE_ARGS[@]}" \
  --group-name "$TEMP_SG_NAME" \
  --description "Temp SG for nf-workshop AMI build - safe to delete" \
  --vpc-id "$VPC_ID" \
  --query 'GroupId' \
  --output text)

aws ec2 authorize-security-group-ingress \
  --region "$AWS_REGION" \
  "${PROFILE_ARGS[@]}" \
  --group-id "$TEMP_SG_ID" \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 > /dev/null

# ── Launch bootstrap instance ─────────────────────────────────────────────────

echo "--- Launching bootstrap instance ---"
INSTANCE_ID=$(aws ec2 run-instances \
  --region "$AWS_REGION" \
  "${PROFILE_ARGS[@]}" \
  --image-id "$BASE_AMI" \
  --instance-type t3.medium \
  --key-name "$TEMP_KEY_NAME" \
  --security-group-ids "$TEMP_SG_ID" \
  --metadata-options "HttpTokens=required,HttpEndpoint=enabled" \
  --block-device-mappings "DeviceName=/dev/sda1,Ebs={VolumeSize=20,VolumeType=gp3}" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=nf-workshop-bootstrap},{Key=workshop,Value=nf-workshop-2026}]" \
  --query 'Instances[0].InstanceId' \
  --output text)
echo "Instance ID: $INSTANCE_ID"

echo "--- Waiting for instance to be running ---"
aws ec2 wait instance-running \
  --region "$AWS_REGION" \
  "${PROFILE_ARGS[@]}" \
  --instance-ids "$INSTANCE_ID"

PUBLIC_IP=$(aws ec2 describe-instances \
  --region "$AWS_REGION" \
  "${PROFILE_ARGS[@]}" \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)
echo "Public IP: $PUBLIC_IP"

# ── Wait for SSH ──────────────────────────────────────────────────────────────

echo "--- Waiting for SSH to be ready ---"
for i in $(seq 1 40); do
  if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes \
       -i "$TEMP_KEY_FILE" ubuntu@"$PUBLIC_IP" true 2>/dev/null; then
    echo "SSH ready."
    break
  fi
  if [[ $i -eq 40 ]]; then
    echo "ERROR: SSH not ready after 400s. Giving up."
    exit 1
  fi
  echo "  Attempt $i/40 — retrying in 10s..."
  sleep 10
done

# ── Copy and run bootstrap.sh ─────────────────────────────────────────────────

echo "--- Copying bootstrap.sh ---"
scp -o StrictHostKeyChecking=no -i "$TEMP_KEY_FILE" \
  "$SCRIPT_DIR/bootstrap.sh" ubuntu@"$PUBLIC_IP":/home/ubuntu/bootstrap.sh

echo "--- Running bootstrap.sh (takes 15-25 minutes) ---"
ssh -o StrictHostKeyChecking=no \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=60 \
    -i "$TEMP_KEY_FILE" \
    ubuntu@"$PUBLIC_IP" \
    "bash /home/ubuntu/bootstrap.sh"

# ── Create AMI ────────────────────────────────────────────────────────────────

echo "--- Creating AMI: $AMI_NAME ---"
NEW_AMI_ID=$(aws ec2 create-image \
  --region "$AWS_REGION" \
  "${PROFILE_ARGS[@]}" \
  --instance-id "$INSTANCE_ID" \
  --name "$AMI_NAME" \
  --description "NF Data Workshop 2026 - pre-installed R, code-server, Claude Code" \
  --no-reboot \
  --query 'ImageId' \
  --output text)
echo "AMI ID: $NEW_AMI_ID"

echo "--- Waiting for AMI to be available (may take 10-15 minutes) ---"
for i in $(seq 1 60); do
  STATE=$(aws ec2 describe-images --region "$AWS_REGION" "${PROFILE_ARGS[@]}" \
    --image-ids "$NEW_AMI_ID" --query 'Images[0].State' --output text 2>/dev/null)
  if [[ "$STATE" == "available" ]]; then
    echo "AMI is available."
    break
  elif [[ "$STATE" == "failed" ]]; then
    echo "ERROR: AMI creation failed."
    exit 1
  fi
  if [[ $i -eq 60 ]]; then
    echo "ERROR: AMI still not available after 30 minutes."
    exit 1
  fi
  echo "  State: ${STATE} — checking again in 30s... ($i/60)"
  sleep 30
done

# ── Update launch scripts ─────────────────────────────────────────────────────

echo "--- Updating AMI_ID in launch scripts ---"
sed -i '' "s|AMI_ID=\"ami-[^\"]*\"|AMI_ID=\"$NEW_AMI_ID\"|" "$SCRIPT_DIR/test-launch.sh"
sed -i '' "s|AMI_ID=\"ami-[^\"]*\"|AMI_ID=\"$NEW_AMI_ID\"|" "$SCRIPT_DIR/launch.sh"

echo ""
echo "=== Done ==="
echo "AMI ID:   $NEW_AMI_ID"
echo "AMI name: $AMI_NAME"
echo ""
echo "Next: bash ec2-setup/test-launch.sh"
