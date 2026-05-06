#!/bin/bash
# AMI bootstrap script.
#
# How to use:
#   1. Launch a fresh Ubuntu 24.04 LTS EC2 instance (t3.medium or larger)
#   2. SSH in and run this script as the ubuntu user:
#        curl -fsSL https://raw.githubusercontent.com/<your-org>/2026-ctf-data-workshop/main/ec2-setup/bootstrap.sh | bash
#      OR copy and run directly.
#   3. When it finishes, create an AMI from the instance in the AWS console.
#   4. Terminate this temporary instance.
#   5. Paste the AMI ID into launch.sh.
#
#   bash bootstrap.sh

set -euo pipefail

echo "=== NF Workshop AMI Bootstrap ==="
echo "Started: $(date)"

# ── System packages ──────────────────────────────────────────────────────────

sudo apt-get update -qq
sudo apt-get install -y -qq \
  curl wget git unzip jq \
  build-essential gfortran libcurl4-openssl-dev libssl-dev libxml2-dev \
  libfontconfig1-dev libharfbuzz-dev libfribidi-dev \
  libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev \
  python3-pip python3-venv

# ── R ────────────────────────────────────────────────────────────────────────

echo "--- Installing R ---"
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc \
  | sudo gpg --dearmor -o /usr/share/keyrings/r-project.gpg
echo "deb [signed-by=/usr/share/keyrings/r-project.gpg] https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/" \
  | sudo tee /etc/apt/sources.list.d/r-project.list
sudo apt-get update -qq
sudo apt-get install -y -qq r-base r-base-dev

# ── R packages ───────────────────────────────────────────────────────────────

echo "--- Installing R packages ---"
sudo Rscript -e "
  options(repos = c(CRAN = 'https://cloud.r-project.org'))
  install.packages('BiocManager')
  BiocManager::install(c('edgeR', 'limma'), ask = FALSE)
  install.packages(c('ggplot2', 'gprofiler2', 'pheatmap', 'dplyr', 'tibble', 'ggrepel', 'enrichR', 'patchwork'))
  cat('R packages installed OK\n')
"

# ── Node.js + Claude Code ────────────────────────────────────────────────────

echo "--- Installing Node.js ---"
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y -qq nodejs

echo "--- Installing Claude Code ---"
sudo npm install -g @anthropic-ai/claude-code

# ── code-server ──────────────────────────────────────────────────────────────

echo "--- Installing code-server ---"
curl -fsSL https://code-server.dev/install.sh | sh

# Configure code-server to open the workshop directory by default
# Password will be set per-instance at launch time via user-data
sudo mkdir -p /home/ubuntu/.config/code-server
sudo tee /home/ubuntu/.config/code-server/config.yaml > /dev/null <<'EOF'
bind-addr: 0.0.0.0:8080
auth: password
password: PLACEHOLDER
cert: false
EOF
sudo chown -R ubuntu:ubuntu /home/ubuntu/.config

# Enable code-server to start on boot
sudo systemctl enable code-server@ubuntu

# ── synapseclient ────────────────────────────────────────────────────────────

echo "--- Installing synapseclient ---"
sudo python3 -m venv /opt/synapse-env
sudo /opt/synapse-env/bin/pip install --quiet synapseclient
sudo ln -sf /opt/synapse-env/bin/synapse /usr/local/bin/synapse

# ── Workshop directory setup ─────────────────────────────────────────────────

mkdir -p /home/ubuntu/nf-workshop/data

# Pre-create a workspace R script participants can use as a starting point
cat > /home/ubuntu/nf-workshop/analysis.R <<'EOF'
# NF Data Workshop — Track 2
# RNA-seq analysis of cNF immortalized Schwann cell lines
# Wallace et al. 2026 (PLOS ONE doi:10.1371/journal.pone.0340183)
#
# Use Claude Code to help you fill in and run this analysis.
# Start Claude Code with: claude

library(edgeR)
library(limma)
library(ggplot2)
library(gprofiler2)
library(pheatmap)
library(dplyr)

# Data files are in the data/ subdirectory
data_dir <- "data"

counts_file   <- file.path(data_dir, "salmon.merged.gene_counts.tsv")
metadata_file <- file.path(data_dir, "samplesheet.valid.csv")

# TODO: load and explore — ask Claude Code for help!
EOF

sudo chown -R ubuntu:ubuntu /home/ubuntu/nf-workshop

echo ""
echo "=== Bootstrap complete ==="
echo "Next steps:"
echo "  1. In the AWS console, create an AMI from this instance"
echo "  2. Note the AMI ID and paste it into launch.sh"
echo "  3. Terminate this instance"
