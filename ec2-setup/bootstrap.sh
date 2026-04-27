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
# This script requires a SYNAPSE_AUTH_TOKEN environment variable to download
# workshop data. Generate a Personal Access Token at:
# https://www.synapse.org/#!PersonalAccessTokens:
#
#   export SYNAPSE_AUTH_TOKEN="your-token-here"
#   bash bootstrap.sh

set -euo pipefail

echo "=== NF Workshop AMI Bootstrap ==="
echo "Started: $(date)"

if [[ -z "${SYNAPSE_AUTH_TOKEN:-}" ]]; then
  echo "ERROR: SYNAPSE_AUTH_TOKEN is not set."
  echo "Generate a token at https://www.synapse.org/#!PersonalAccessTokens: and export it before running this script."
  exit 1
fi

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
pip3 install --break-system-packages synapseclient

# ── Workshop data ─────────────────────────────────────────────────────────────

echo "--- Downloading workshop data from Synapse ---"
mkdir -p /home/ubuntu/nf-workshop/data

# Authenticate synapseclient using PAT
python3 - <<PYEOF
import synapseclient
syn = synapseclient.Synapse()
syn.login(authToken="${SYNAPSE_AUTH_TOKEN}")

# Download processed RNA-seq data from syn29529772 (star_salmon outputs)
# Primary count matrix: salmon.merged.gene_counts.tsv (syn29532377 v2)
# Sample metadata:      samplesheet.valid.csv          (syn29530880 v3)
# DESeq2 PCA values:    deseq2.pca.vals.txt            (syn29530871)
files_to_download = [
    "syn29532377",  # salmon.merged.gene_counts.tsv  — gene-level counts, all samples
    "syn29530880",  # samplesheet.valid.csv           — sample metadata
    "syn29530871",  # deseq2.pca.vals.txt             — pre-computed PCA for reference
    "syn29530869",  # deseq2.plots.pdf                — pre-computed QC plots for reference
]

for syn_id in files_to_download:
    entity = syn.get(syn_id, downloadLocation="/home/ubuntu/nf-workshop/data")
    print(f"Downloaded: {entity.path}")

print("Data download complete.")
PYEOF

sudo chown -R ubuntu:ubuntu /home/ubuntu/nf-workshop

# ── Workshop directory setup ─────────────────────────────────────────────────

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

echo ""
echo "=== Bootstrap complete ==="
echo "Next steps:"
echo "  1. In the AWS console, create an AMI from this instance"
echo "  2. Note the AMI ID and paste it into launch.sh"
echo "  3. Terminate this instance"
