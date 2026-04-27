#!/bin/bash
# Run once to create the security group for workshop instances.
# Outputs the security group ID — paste it into launch.sh.

set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
VPC_ID="${VPC_ID:-}"  # leave blank to use default VPC

if [[ -z "$VPC_ID" ]]; then
  VPC_ID=$(aws ec2 describe-vpcs \
    --region "$AWS_REGION" \
    --filters Name=isDefault,Values=true \
    --query 'Vpcs[0].VpcId' \
    --output text)
  echo "Using default VPC: $VPC_ID"
fi

SG_ID=$(aws ec2 create-security-group \
  --region "$AWS_REGION" \
  --group-name "nf-workshop-2026" \
  --description "NF Data Workshop 2026 — code-server access" \
  --vpc-id "$VPC_ID" \
  --query 'GroupId' \
  --output text)

echo "Created security group: $SG_ID"

# Allow inbound on port 8080 (code-server) from anywhere
aws ec2 authorize-security-group-ingress \
  --region "$AWS_REGION" \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0

# Allow all outbound (needed for R packages, npm, Anthropic API, Synapse)
aws ec2 authorize-security-group-egress \
  --region "$AWS_REGION" \
  --group-id "$SG_ID" \
  --protocol -1 \
  --cidr 0.0.0.0/0 2>/dev/null || true  # default VPCs already have this rule

echo ""
echo "Security group ready: $SG_ID"
echo "Add this to launch.sh: SECURITY_GROUP_ID=\"$SG_ID\""
