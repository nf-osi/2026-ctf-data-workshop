#!/bin/bash
# Launches a single EC2 instance for testing the workshop environment.
# Prints the URL and password directly — no CSV output.

set -euo pipefail

# ── Configuration — edit these ────────────────────────────────────────────────

AWS_REGION="us-east-1"
AWS_PROFILE="${AWS_PROFILE:-}"

# Load credentials from untracked file if present
CREDS_FILE="$(dirname "${BASH_SOURCE[0]}")/credentials.env"
[[ -f "$CREDS_FILE" ]] && source "$CREDS_FILE"
AMI_ID="ami-0391a51b1900842a3"
INSTANCE_TYPE="t3.medium"
SECURITY_GROUP_ID="sg-02d132f299a34e5b1"
INSTANCE_PROFILE_ARN=""  # optional, for SSM access

# ── Launch ────────────────────────────────────────────────────────────────────

PROFILE_ARGS=()
[[ -n "$AWS_PROFILE" ]] && PROFILE_ARGS=(--profile "$AWS_PROFILE")

PASSWORD=$(openssl rand -base64 12 | tr -d '/+=')

USER_DATA=$(cat <<USERDATA
#!/bin/bash
npm install -g @anthropic-ai/claude-code@latest

echo 'export ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}' >> /home/ubuntu/.bashrc
echo 'export ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}' >> /home/ubuntu/.profile

mkdir -p /home/ubuntu/.config/code-server
cat > /home/ubuntu/.config/code-server/config.yaml <<CONF
bind-addr: 0.0.0.0:8080
auth: password
password: ${PASSWORD}
cert: true
app-name: NF Data Workshop 2026
CONF

mkdir -p /home/ubuntu/.local/share/code-server/User
cat > /home/ubuntu/.local/share/code-server/User/settings.json <<VSSETTINGS
{
  "workbench.startupEditor": "none",
  "workbench.tips.enabled": false,
  "workbench.welcomePage.walkthroughs.openOnInstall": false,
  "workbench.colorTheme": "Default Dark Modern",
  "editor.minimap.enabled": false,
  "terminal.integrated.defaultProfile.linux": "bash",
  "extensions.ignoreRecommendations": true
}
VSSETTINGS

mkdir -p /home/ubuntu/.claude
cat > /home/ubuntu/.claude/settings.json <<CLAUDESETTINGS
{
  "model": "claude-sonnet-4-6",
  "permissions": {
    "allow": [],
    "deny": []
  }
}
CLAUDESETTINGS
cat > /home/ubuntu/.claude.json <<CLAUDEJSON
{
  "hasCompletedOnboarding": true,
  "oauthAccount": null
}
CLAUDEJSON

mkdir -p /home/ubuntu/nf-workshop/data

# Ensure synapseclient is available (reinstall into venv if missing)
if ! command -v synapse &>/dev/null; then
  python3 -m venv /opt/synapse-env
  /opt/synapse-env/bin/pip install --quiet synapseclient
  ln -sf /opt/synapse-env/bin/synapse /usr/local/bin/synapse
fi

chown -R ubuntu:ubuntu /home/ubuntu/.config /home/ubuntu/.local /home/ubuntu/.claude /home/ubuntu/nf-workshop
chown ubuntu:ubuntu /home/ubuntu/.claude.json

systemctl enable --now code-server@ubuntu
USERDATA
)

RUN_ARGS=(
  --region "$AWS_REGION"
  "${PROFILE_ARGS[@]}"
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
  "${PROFILE_ARGS[@]}" \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo ""
echo "  URL:      https://${PUBLIC_IP}:8080/?folder=/home/ubuntu/nf-workshop"
echo "  Password: ${PASSWORD}"
echo ""
echo "Note: code-server may take another 30-60 seconds to finish starting up."
echo "To tear down: bash test-teardown.sh $INSTANCE_ID"
