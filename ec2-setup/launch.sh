#!/bin/bash
# Launches N EC2 instances for workshop participants.
# Run this the morning of the workshop.
# Outputs credentials.csv with one row per participant (URL + password).

set -euo pipefail

# ── Configuration — edit these before the workshop ───────────────────────────

AWS_REGION="us-east-1"
AMI_ID="ami-XXXXXXXXXXXXXXXXX"         # AMI saved after running bootstrap.sh
INSTANCE_TYPE="t3.medium"
SECURITY_GROUP_ID="sg-XXXXXXXXXXXXXXXXX"  # output of security-group.sh
N_PARTICIPANTS=20
ANTHROPIC_API_KEY="sk-ant-XXXXXXXXXXXX"   # API key for Claude Code

# Optional: attach an instance profile with AmazonSSMManagedInstanceCore
# so you can access instances without SSH if needed for debugging.
# Create it in IAM and paste the ARN here, or leave blank.
INSTANCE_PROFILE_ARN=""

# ── Don't edit below this line ────────────────────────────────────────────────

WORKSHOP_TAG="nf-workshop-2026"
OUTPUT_FILE="credentials.csv"

echo "Launching $N_PARTICIPANTS instances in $AWS_REGION..."
echo "participant,url,password" > "$OUTPUT_FILE"

for i in $(seq 1 "$N_PARTICIPANTS"); do
  PASSWORD=$(openssl rand -base64 12 | tr -d '/+=')

  USER_DATA=$(cat <<USERDATA
#!/bin/bash
# Set unique code-server password
mkdir -p /home/ubuntu/.config/code-server
cat > /home/ubuntu/.config/code-server/config.yaml <<CONF
bind-addr: 0.0.0.0:8080
auth: password
password: ${PASSWORD}
cert: false
CONF
chown -R ubuntu:ubuntu /home/ubuntu/.config

# Inject API key
echo 'export ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}' >> /home/ubuntu/.bashrc
echo 'export ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}' >> /home/ubuntu/.profile

# Start code-server and open workshop directory by default
systemctl start code-server@ubuntu
systemctl enable code-server@ubuntu

# Write a welcome message to the terminal on login
cat >> /home/ubuntu/.bashrc <<'BANNER'

echo ""
echo "  Welcome to the NF Data Workshop!"
echo "  Your workshop files are in: ~/nf-workshop/"
echo "  Start Claude Code with:     claude"
echo ""
BANNER
USERDATA
)

  # Build run-instances arguments
  RUN_ARGS=(
    --region "$AWS_REGION"
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
    --instance-ids "$instance_id" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

  URL="http://${PUBLIC_IP}:8080"
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
