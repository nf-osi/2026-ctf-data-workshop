# Track 2: Using Claude Code to Explore cNF RNA-seq Data

## Before You Start

Make sure you have:
- Connected to your workshop EC2 environment (see [setup.md](setup.md))
- A terminal open in the VS Code interface
- Logged in to [synapse.org](https://www.synapse.org) in your browser — you will need this to find and download data in Part 2

---

## How This Works

In this track you will explore a real NF1 research dataset using **Claude Code** — an AI assistant that lives in your terminal. You ask it scientific questions in plain English. It figures out how to answer them, writes and runs whatever code is needed, and shows you the results.

You are the scientist. Claude Code is your analyst.

A few things worth knowing before you start:

- **Claude Code remembers your conversation.** You can build on previous questions, ask follow-ups, or say "actually, do that differently."
- **You can ask it to explain itself.** If it does something you don't understand, ask "what did you just do and why?"
- **It will make mistakes sometimes.** If a result looks wrong, say so. It will debug and retry.
- **There are no wrong questions.** The prompts in this guide are starting points — go off-script whenever something looks interesting.

---

## Part 1: Understand the Study

### Read the paper

Open the paper in your browser:

> Wallace et al., "Immortalization and characterization of Schwann cell lines derived from NF1-associated cutaneous neurofibromas." *PLOS ONE*, 2026.
> **[https://doi.org/10.1371/journal.pone.0340183](https://doi.org/10.1371/journal.pone.0340183)**

You don't need to read every word. Focus on:

- **Abstract** — what did the researchers make, and why?
- **Figure 5** — four panels showing the RNA-seq results: a PCA plot, a volcano plot, a heatmap, and pathway enrichment results. This is what you will reproduce and extend.
- **Data Availability** — where is the data deposited?

**Key biology to keep in mind:**

The study took Schwann cells from cutaneous neurofibromas (cNF tumors from NF1 patients), immortalized them using two genetic tricks (hTERT and mCdk4), and then asked: *do the immortalized cells still behave like the original tumor cells?* RNA-seq is how they answered that question.

You have 14 samples: 7 primary cultures (the original cells) and 7 immortalized lines, matched by donor.

---

## Part 2: Find the Data

### Navigate to the NF Data Portal

1. Go to **[nf.synapse.org](https://nf.synapse.org)** and log in with your Synapse account
2. Explore the data catalog — can you find a dataset related to this paper?
3. Navigate to the full data collection: [https://doi.org/10.7303/syn11374339](https://doi.org/10.7303/syn11374339)
4. Browse the folder structure. What types of data are available beyond RNA-seq?

### Download the data using Claude Code

Open a terminal in VS Code and start Claude Code:

```bash
claude
```

Then ask Claude Code to download the two files you need from Synapse. It will use the `synapse` command-line client that is pre-installed on your machine. You will need to provide your Synapse username and password when it asks.

> *"Please download the RNA-seq count matrix (syn29532377) and sample metadata (syn29530880) from Synapse into the `data/` folder."*

Once it's done you should have:

```
~/nf-workshop/data/
├── salmon.merged.gene_counts.tsv
└── samplesheet.valid.csv
```

---

## Part 3: Explore with Claude Code

### Orient Claude Code to the dataset

Now that the data is downloaded, give Claude Code context about what you're working with. Something like:

> *"I'm working with RNA-seq data from a study of NF1 cutaneous neurofibroma Schwann cells. There are 14 samples: 7 primary cultures and 7 immortalized Schwann cell lines, matched by donor. The count matrix is in `data/salmon.merged.gene_counts.tsv` and the sample metadata is in `data/samplesheet.valid.csv`. Please load the data, check it looks correct, and give me a brief summary of what we're working with."*

Claude Code will load the files, tell you about the data structure, and flag anything unusual. Read its response — this is useful context for everything that follows.

---

### Checkpoint 1 — Quality and overview

Get a feel for the data before diving into results.

**Ask something like:**
> *"Are there any outlier samples I should know about? Show me a PCA plot colored by condition and save it as a PDF."*

**Follow-up ideas:**
- "Do matched pairs (same donor, primary vs. immortalized) cluster together?"
- "What fraction of the variance do PC1 and PC2 explain, and what does that tell us?"
- "Show me the sample-to-sample correlation heatmap."

**What to look for:** Your PCA should broadly match **Figure 5A** in the paper — the two conditions should separate. If they don't, something may be wrong with how the metadata was matched to the counts.

---

### Checkpoint 2 — What changed?

Ask the central biological question of the study.

**Ask something like:**
> *"What genes are most significantly changed by immortalization? Run a differential expression analysis comparing immortalized to primary cells, accounting for the paired donor design. Make a volcano plot and save it as a PDF."*

**Follow-up ideas:**
- "How many genes are significantly up or down?"
- "What are the top 20 most upregulated genes? Do any of them make biological sense given that we introduced hTERT and mCdk4?"
- "Where does NF1 itself fall on the volcano plot? Is its expression affected by immortalization?"
- "Label the top 10 most significant genes on the volcano plot."

**What to look for:** The paper reports 993 differentially expressed genes using adjusted p < 0.05 and |log2FC| > 2. Your number should be in the same ballpark — exact agreement depends on implementation choices.

---

### Checkpoint 3 — Gene set enrichment with Enrichr

This is where it gets interesting. Instead of just listing differentially expressed genes, ask Claude Code to find out what *biological programs* are activated or suppressed.

**Ask something like:**
> *"Use Enrichr to run gene set enrichment on the genes upregulated in immortalized cells. Query the MSigDB Hallmarks, KEGG 2021, and DisGeNET databases. What pathways and diseases are most enriched?"*

Then flip it:
> *"Do the same for genes upregulated in primary cells — what are we losing when we immortalize? Are Schwann cell identity programs being downgraded?"*

**Follow-up ideas:**
- "The DisGeNET results are interesting — are any NF1 or neurofibroma-related terms enriched? What about other cancers?"
- "Run enrichment on just the top 100 most upregulated genes. Does the picture change?"
- "Visualize the top enriched terms from each condition as a bar chart and save it."
- "Cross-reference the upregulated genes against a list of known NF1-pathway genes. How much overlap is there?"

**What to look for:** Immortalized cells should strongly enrich for cell cycle and proliferation pathways — expected because mCdk4 drives cell division. The primary cells (genes lost during immortalization) may show enrichment for Schwann cell differentiation and myelination terms.

---

### Checkpoint 4 — Dig into the biology

Pick a thread from Checkpoint 3 that surprised you and pull on it.

Some directions that are worth exploring:

**Schwann cell identity:**
> *"Make a plot showing the expression of key Schwann cell markers (S100B, MPZ, PMP22, SOX10) across all 14 samples. Are the immortalized cells still recognizably Schwann cells at the transcriptome level?"*

**The NF1 pathway:**
> *"Plot the expression of NF1 and key RAS/MAPK pathway genes (KRAS, HRAS, BRAF, MAP2K1, MAPK1, MAPK3) across all samples. Does anything stand out?"*

**Drug targets:**
> *"Of the genes most upregulated in immortalized cells, which ones are known drug targets? Are any of them targeted by drugs that are already in clinical use or in trials for NF1?"*

**Transcription factors:**
> *"Use Enrichr's ENCODE_and_ChEA_Consensus_TFs_from_ChIP-X database to find transcription factors whose targets are enriched in the upregulated gene set. Which transcription factors might be driving the immortalization signature?"*

---

### Checkpoint 5 — Make something shareable

Bring the analysis together.

**Ask something like:**
> *"Generate a single summary figure combining the PCA, volcano plot, and a bar chart of the top 10 Enrichr Hallmark terms for each condition. Arrange them in a grid and save as summary_figure.pdf."*

Then:
> *"Write a 3-sentence plain language summary of what this RNA-seq data tells us about these immortalized cNF Schwann cell lines — suitable for someone who doesn't know bioinformatics."*

---

### Open exploration

You have time — go wherever the data takes you. Some starting points if you're not sure where to go:

- "What are the most highly expressed genes in primary cNF cells overall? Are any of them potential biomarkers?"
- "Is there any evidence of epithelial-to-mesenchymal transition in the immortalized cells?"
- "Compare the expression pattern of these samples to what you know about NF1-related malignant peripheral nerve sheath tumors (MPNSTs). Do the immortalized cells look more like cNF or more like MPNST?"
- "Show me a heatmap of the top 50 differentially expressed genes across all 14 samples."
- "Can you write a methods section paragraph describing the analysis we just did?"

---

## Part 4: Reflect

1. What result surprised you the most?
2. The immortalized cell lines were created as a tool for studying cNF. Based on everything you just found, would you trust them as a model for NF1 biology? What caveats would you mention?
3. What question would you ask next if you had more time?
4. How did using Claude Code change how you approached this analysis compared to how you would have done it before?

---

[← Back to Track 2 overview](README.md) | [← Back to workshop home](../README.md)
