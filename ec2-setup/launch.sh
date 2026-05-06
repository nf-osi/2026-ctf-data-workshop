#!/bin/bash
# Launches N EC2 instances for workshop participants.
# Run this the morning of the workshop.
# Outputs credentials.csv with one row per participant (URL + password).

set -euo pipefail

# ── Configuration — edit these before the workshop ───────────────────────────

AWS_REGION="us-east-1"
AWS_PROFILE="${AWS_PROFILE:-}"

# Load credentials from untracked file if present
CREDS_FILE="$(dirname "${BASH_SOURCE[0]}")/credentials.env"
[[ -f "$CREDS_FILE" ]] && source "$CREDS_FILE"
AMI_ID="ami-0391a51b1900842a3"
INSTANCE_TYPE="t3.medium"
SECURITY_GROUP_ID="sg-02d132f299a34e5b1"
N_PARTICIPANTS=20
# Optional: attach an instance profile with AmazonSSMManagedInstanceCore
# so you can access instances without SSH if needed for debugging.
# Create it in IAM and paste the ARN here, or leave blank.
INSTANCE_PROFILE_ARN=""

# ── Don't edit below this line ────────────────────────────────────────────────

PROFILE_ARGS=()
[[ -n "$AWS_PROFILE" ]] && PROFILE_ARGS=(--profile "$AWS_PROFILE")

WORKSHOP_TAG="nf-workshop-2026"
OUTPUT_FILE="credentials.csv"

echo "Launching $N_PARTICIPANTS instances in $AWS_REGION..."
echo "participant,url,password" > "$OUTPUT_FILE"

for i in $(seq 1 "$N_PARTICIPANTS"); do
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

cat >> /home/ubuntu/.bashrc <<'BANNER'

echo ""
echo "  Welcome to the NF Data Workshop!"
echo "  Your workshop files are in: ~/nf-workshop/"
echo "  Start Claude Code with:     claude"
echo ""
BANNER

systemctl enable --now code-server@ubuntu
USERDATA
)

  # Build run-instances arguments
  RUN_ARGS=(
    --region "$AWS_REGION"
    "${PROFILE_ARGS[@]}"
    --image-id "$AMI_ID"
    --instance-type "$INSTANCE_TYPE"
    --security-group-ids "$SECURITY_GROUP_ID"
    --user-data "$USER_DATA"
    --tag-specifications "ResourceType=instance,Tags=[{Key=workshop,Value=${WORKSHOP_TAG}},{Key=participant,Value=participant-${i}}]"
    --metadata-options "HttpTokens=required,HttpEndpoint=enabled"
    --query 'Instances[0].InstanceId'
    --output text
  )

  if [[ -n "$INSTANCE_PROFILE_ARN" ]]; then
    RUN_ARGS+=(--iam-instance-profile "Arn=${INSTANCE_PROFILE_ARN}")
  fi

  INSTANCE_ID=$(aws ec2 run-instances "${RUN_ARGS[@]}")
  echo "  Launched participant $i: $INSTANCE_ID"

  # Store instance ID mapped to password; resolve public IP after launch
  echo "${i}|${INSTANCE_ID}|${PASSWORD}" >> /tmp/workshop_instances_$$.txt
done

echo ""
echo "Waiting 60 seconds for instances to get public IPs..."
sleep 60

# Resolve public IPs and write final credentials CSV
while IFS='|' read -r participant instance_id password; do
  PUBLIC_IP=$(aws ec2 describe-instances \
    --region "$AWS_REGION" \
    "${PROFILE_ARGS[@]}" \
    --instance-ids "$instance_id" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

  URL="https://${PUBLIC_IP}:8080/?folder=/home/ubuntu/nf-workshop"
  echo "participant-${participant},${URL},${password}" >> "$OUTPUT_FILE"
  echo "  Participant $participant: $URL  password: $password"
done < /tmp/workshop_instances_$$.txt

rm -f /tmp/workshop_instances_$$.txt

echo ""
echo "Done. Credentials saved to: $OUTPUT_FILE"
echo "Share this file with participants (e.g. print it or add to a spreadsheet)."
echo ""
echo "IMPORTANT: Keep ANTHROPIC_API_KEY out of any shared files — it is baked"
echo "into each instance and does not appear in credentials.csv."
