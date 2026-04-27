# Track 2 Setup Guide

## Option A: Use the Workshop EC2 Environment (recommended)

The workshop provides a pre-configured cloud environment for each participant. You do not need to install anything.

### What you need

- A laptop with Chrome or Firefox
- The URL and password provided on your workshop credential card

### How to connect

1. Open Chrome or Firefox
2. Navigate to the URL on your credential card (looks like `http://12.34.56.78:8080`)
3. Enter the password from your credential card
4. You will see a VS Code interface running in your browser

### Find your workshop files

In the VS Code interface, open a terminal:
- Menu → Terminal → New Terminal
- Or press `` Ctrl+` ``

Your workshop files are pre-loaded:

```
~/nf-workshop/
├── analysis.R          ← starter R script
└── data/
    ├── salmon.merged.gene_counts.tsv   ← RNA-seq count matrix (all 14 samples)
    ├── samplesheet.valid.csv           ← sample metadata
    ├── deseq2.pca.vals.txt             ← pre-computed PCA values (for reference)
    └── deseq2.plots.pdf                ← pre-computed QC plots (for reference)
```

Navigate there with:

```bash
cd ~/nf-workshop
```

### Start Claude Code

```bash
claude
```

You are ready to go. Jump to [Part 3 of the instructions](instructions.md#part-3-analyze-the-data).

---

## Option B: Run Locally

If you prefer to work on your own machine, you can replicate the environment. This takes 10–20 minutes.

### 1. Install R

**macOS:** Download the `.pkg` from [cran.r-project.org/bin/macosx](https://cran.r-project.org/bin/macosx/)

**Windows:** Download the installer from [cran.r-project.org/bin/windows/base](https://cran.r-project.org/bin/windows/base/)

Verify: `Rscript --version`

### 2. Install R packages

```bash
Rscript -e "install.packages('BiocManager', repos='https://cloud.r-project.org')"
Rscript -e "BiocManager::install(c('edgeR', 'limma'))"
Rscript -e "install.packages(c('ggplot2', 'gprofiler2', 'pheatmap', 'dplyr', 'tibble', 'ggrepel'), repos='https://cloud.r-project.org')"
```

Verify: `Rscript -e "library(edgeR); library(limma); library(ggplot2); cat('OK\n')"`

### 3. Install Node.js

Download the LTS installer from [nodejs.org](https://nodejs.org).

Verify: `node --version` (must be v18 or higher)

### 4. Install Claude Code

```bash
npm install -g @anthropic-ai/claude-code
```

### 5. Set your API key

**macOS/Linux:**
```bash
export ANTHROPIC_API_KEY=<your-key>
```

**Windows (PowerShell):**
```powershell
$env:ANTHROPIC_API_KEY="<your-key>"
```

### 6. Download the workshop data

Log in to [synapse.org](https://www.synapse.org), then download these two files from the NF Data Portal:

| File | Synapse ID | How to download |
|------|-----------|----------------|
| `salmon.merged.gene_counts.tsv` | [syn29532377](https://www.synapse.org/Synapse:syn29532377) | Click the download icon |
| `samplesheet.valid.csv` | [syn29530880](https://www.synapse.org/Synapse:syn29530880) | Click the download icon |

Create a `nf-workshop/data/` folder and place both files inside it.

### 7. Test Claude Code

```bash
cd nf-workshop
claude
```

Type a message to confirm it responds, then `/exit`.

---

[← Back to Track 2 instructions](instructions.md) | [← Back to workshop home](../README.md)
