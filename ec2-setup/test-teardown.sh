#!/bin/bash
# Terminates the test EC2 instance.
# Usage: bash test-teardown.sh <instance-id>
#   OR:  bash test-teardown.sh          (finds any running test instance by tag)

set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"

if [[ -n "${1:-}" ]]; then
  INSTANCE_ID="$1"
else
  INSTANCE_ID=$(aws ec2 describe-instances \
    --region "$AWS_REGION" \
    --filters \
      "Name=tag:participant,Values=test" \
      "Name=tag:workshop,Values=nf-workshop-2026" \
      "Name=instance-state-name,Values=running,stopped,pending" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text)

  if [[ -z "$INSTANCE_ID" || "$INSTANCE_ID" == "None" ]]; then
    echo "No test instance found."
    exit 0
  fi

  echo "Found test instance: $INSTANCE_ID"
fi

aws ec2 terminate-instances \
  --region "$AWS_REGION" \
  --instance-ids "$INSTANCE_ID" \
  --query 'TerminatingInstances[0].{ID:InstanceId,State:CurrentState.Name}' \
  --output table

echo "Done."
