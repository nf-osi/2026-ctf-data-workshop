# Track 2 Setup Guide: Claude Code + R

This guide walks you through everything you need to install before the workshop. **Please complete this before you arrive** — installation can take 10–20 minutes depending on your internet connection.

If you get stuck, ask a facilitator or email the workshop organizers.

---

## What You Are Installing

| Tool | Purpose |
|------|---------|
| **R** | The statistical computing language used for RNA-seq analysis |
| **R packages** | Libraries that extend R with bioinformatics tools |
| **Node.js** | Required to run Claude Code |
| **Claude Code** | AI assistant in your terminal — your co-analyst for this workshop |

---

## Step 1: Install R

### macOS

1. Go to [https://cran.r-project.org/bin/macosx/](https://cran.r-project.org/bin/macosx/)
2. Download the latest `.pkg` file for your Mac (check whether you have an Apple Silicon or Intel chip — it matters)
3. Open the downloaded file and follow the installer

### Windows

1. Go to [https://cran.r-project.org/bin/windows/base/](https://cran.r-project.org/bin/windows/base/)
2. Click "Download R for Windows" and run the installer
3. Accept the default options throughout

### Verify

Open a terminal (macOS: Terminal app; Windows: Command Prompt or PowerShell) and run:

```
Rscript --version
```

You should see something like `R scripting front-end version 4.x.x`. If you get an error, R is not on your PATH — ask a facilitator.

---

## Step 2: Install R Packages

Open a terminal and run:

```
Rscript -e "install.packages('BiocManager', repos='https://cloud.r-project.org')"
Rscript -e "BiocManager::install(c('edgeR', 'limma'))"
Rscript -e "install.packages(c('ggplot2', 'gprofiler2', 'pheatmap', 'dplyr', 'tibble'), repos='https://cloud.r-project.org')"
```

This may take several minutes. You may be prompted to install from source — type `n` and press Enter to use pre-built binaries (faster).

### Verify

```
Rscript -e "library(edgeR); library(limma); library(ggplot2); library(gprofiler2); cat('All packages loaded OK\n')"
```

You should see `All packages loaded OK`.

---

## Step 3: Install Node.js

Claude Code requires Node.js version 18 or higher.

### macOS

1. Go to [https://nodejs.org](https://nodejs.org)
2. Download and install the **LTS** version

### Windows

1. Go to [https://nodejs.org](https://nodejs.org)
2. Download and run the **LTS** installer
3. Accept the default options (make sure "Add to PATH" is checked)

### Verify

```
node --version
```

You should see `v18.x.x` or higher.

---

## Step 4: Install Claude Code

```
npm install -g @anthropic-ai/claude-code
```

### Verify

```
claude --version
```

---

## Step 5: Set Your API Key

You will receive an API key from the workshop organizers. Set it in your terminal:

### macOS / Linux

```
export ANTHROPIC_API_KEY=<your-key-here>
```

To avoid setting this every time you open a new terminal, add it to your shell profile:

```
echo 'export ANTHROPIC_API_KEY=<your-key-here>' >> ~/.zshrc
```

(Replace `.zshrc` with `.bash_profile` if you use bash.)

### Windows (Command Prompt)

```
set ANTHROPIC_API_KEY=<your-key-here>
```

### Windows (PowerShell)

```
$env:ANTHROPIC_API_KEY="<your-key-here>"
```

---

## Step 6: Create a Workshop Directory

Create a folder on your computer where you will do your analysis:

```
mkdir nf-workshop
cd nf-workshop
```

Keep this terminal window open — you will use it throughout the workshop.

---

## Step 7: Test Claude Code

From your `nf-workshop` directory, run:

```
claude
```

You should see the Claude Code prompt. Type a test message:

```
Hello! Can you confirm you are working correctly and tell me one interesting fact about NF1?
```

Press Enter. If you get a response, you are ready for the workshop.

Type `/exit` to close Claude Code.

---

## Troubleshooting

**`claude: command not found`**
- Try closing and reopening your terminal, then run `claude --version` again
- On macOS, you may need to add npm's global bin directory to your PATH: `export PATH="$PATH:$(npm bin -g)"`

**R packages fail to install**
- Make sure you have an internet connection
- On macOS, you may need to install Xcode Command Line Tools: `xcode-select --install`
- On Windows, try running Command Prompt as Administrator

**API key not working**
- Double-check the key was pasted correctly with no extra spaces
- Make sure the `export` (macOS) or `set` (Windows) command ran without errors

---

[← Back to Track 2 instructions](instructions.md) | [← Back to workshop home](../README.md)
