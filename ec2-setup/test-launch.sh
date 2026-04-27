#!/bin/bash
# Launches a single EC2 instance for testing the workshop environment.
# Prints the URL and password directly — no CSV output.

set -euo pipefail

# ── Configuration — edit these ────────────────────────────────────────────────

AWS_REGION="us-east-1"
AMI_ID="ami-XXXXXXXXXXXXXXXXX"
INSTANCE_TYPE="t3.medium"
SECURITY_GROUP_ID="sg-XXXXXXXXXXXXXXXXX"
ANTHROPIC_API_KEY="sk-ant-XXXXXXXXXXXX"
INSTANCE_PROFILE_ARN=""  # optional, for SSM access

# ── Launch ────────────────────────────────────────────────────────────────────

PASSWORD=$(openssl rand -base64 12 | tr -d '/+=')

USER_DATA=$(cat <<USERDATA
#!/bin/bash
mkdir -p /home/ubuntu/.config/code-server
cat > /home/ubuntu/.config/code-server/config.yaml <<CONF
bind-addr: 0.0.0.0:8080
auth: password
password: ${PASSWORD}
cert: false
CONF
chown -R ubuntu:ubuntu /home/ubuntu/.config
echo 'export ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}' >> /home/ubuntu/.bashrc
echo 'export ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}' >> /home/ubuntu/.profile
systemctl enable --now code-server@ubuntu
USERDATA
)

RUN_ARGS=(
  --region "$AWS_REGION"
  --image-id "$AMI_ID"
  --instance-type "$INSTANCE_TYPE"
  --security-group-ids "$SECURITY_GROUP_ID"
  --user-data "$USER_DATA"
  --tag-specifications "ResourceType=instance,Tags=[{Key=workshop,Value=nf-workshop-2026},{Key=participant,Value=test}]"
  --metadata-options "HttpTokens=required,HttpEndpoint=enabled"
  --query 'Instances[0].InstanceId'
  --output text
)

if [[ -n "$INSTANCE_PROFILE_ARN" ]]; then
  RUN_ARGS+=(--iam-instance-profile "Arn=${INSTANCE_PROFILE_ARN}")
fi

echo "Launching test instance..."
INSTANCE_ID=$(aws ec2 run-instances "${RUN_ARGS[@]}")
echo "Instance ID: $INSTANCE_ID"

echo "Waiting for public IP..."
sleep 30
PUBLIC_IP=$(aws ec2 describe-instances \
  --region "$AWS_REGION" \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo ""
echo "  URL:      http://${PUBLIC_IP}:8080"
echo "  Password: ${PASSWORD}"
echo ""
echo "Note: code-server may take another 30-60 seconds to finish starting up."
echo "To tear down: bash test-teardown.sh $INSTANCE_ID"
