#!/bin/bash
# Terminates all workshop EC2 instances tagged with the workshop tag.
# Run at the end of the workshop day.

set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
WORKSHOP_TAG="nf-workshop-2026"

echo "Finding workshop instances in $AWS_REGION..."

INSTANCE_IDS=$(aws ec2 describe-instances \
  --region "$AWS_REGION" \
  --filters \
    "Name=tag:workshop,Values=${WORKSHOP_TAG}" \
    "Name=instance-state-name,Values=running,stopped,pending" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text)

if [[ -z "$INSTANCE_IDS" ]]; then
  echo "No running workshop instances found."
  exit 0
fi

COUNT=$(echo "$INSTANCE_IDS" | wc -w | tr -d ' ')
echo "Found $COUNT instance(s): $INSTANCE_IDS"
echo ""
read -rp "Terminate all $COUNT instance(s)? This cannot be undone. [y/N] " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Aborted."
  exit 0
fi

aws ec2 terminate-instances \
  --region "$AWS_REGION" \
  --instance-ids $INSTANCE_IDS \
  --query 'TerminatingInstances[].{ID:InstanceId,State:CurrentState.Name}' \
  --output table

echo ""
echo "Instances terminated. They will disappear from the console within a few minutes."
