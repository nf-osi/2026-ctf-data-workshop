# Track 2 Instructions: Using AI to Analyze cNF RNA-seq Data

## Before You Start

Make sure you have:
- A laptop with Chrome or Firefox
- Logged in to your [Synapse account](https://www.synapse.org) — if you don't have one, see [SETUP.md](../SETUP.md)

---

## Part 1: Understand the Study

### Step 1.1 — Read the paper

Open the paper:

> Wallace et al., "Immortalization and characterization of Schwann cell lines derived from NF1-associated cutaneous neurofibromas." *PLOS ONE*, 2026.
> **[https://doi.org/10.1371/journal.pone.0340183](https://doi.org/10.1371/journal.pone.0340183)**

You don't need to read every word. Focus on these sections:

- **Abstract** — What is the study about? What did the researchers make, and why?
- **Introduction** — Why are cNF cell lines useful? What problem do they solve for NF1 researchers?
- **RNA-seq section of Methods** — What technology was used, how many samples, and how was the data analyzed?
- **Figure 5** — This is the key RNA-seq figure. It has four panels: a PCA plot, a volcano plot, a heatmap, and pathway enrichment results.
- **Data Availability statement** — Where is the data deposited?

**Discussion questions:**
- The study compares two conditions: primary Schwann cells vs. immortalized Schwann cells. What does "immortalized" mean, and why does it matter for research?
- In Figure 5A (PCA), what does the separation between the two groups tell you?
- In Figure 5B (volcano plot), what do the colors represent? What does the x-axis measure?
- The paper notes that *NF1* gene expression is **not** significantly different between the two conditions. Why is this an important finding for the cell lines to be useful as NF1 disease models?

---

## Part 2: Find the Data

### Step 2.1 — Navigate to the NF Data Portal

The paper's data is hosted on the [NF Data Portal](https://nf.synapse.org), a resource maintained by Sage Bionetworks and the Children's Tumor Foundation.

1. Go to **[nf.synapse.org](https://nf.synapse.org)**
2. Browse the data catalog and look for datasets related to cutaneous neurofibromas or the Wallace et al. paper
3. Alternatively, go directly to the Synapse collection linked in the paper's Data Availability section

> **Tip:** The full data collection lives at [https://doi.org/10.7303/syn11374339](https://doi.org/10.7303/syn11374339)

### Step 2.2 — Explore the Synapse collection

1. Navigate to [synapse.org](https://www.synapse.org) and log in
2. Go to Synapse ID **syn11374339** (type it in the search bar or paste it into the URL: `https://www.synapse.org/Synapse:syn11374339`)
3. Explore the files and folders. Can you find:
   - Raw RNA-seq data?
   - Processed RNA-seq data?
   - Metadata files describing the samples?

### Step 2.3 — Locate the processed RNA-seq data

For this workshop we will use the **processed RNA-seq data** — this is the output of the alignment and quantification pipeline, ready for downstream analysis.

1. Navigate to Synapse ID **syn29529772**
2. Review the files available. You should see gene-level count matrices and associated metadata.
3. Download the files you will need for analysis:
   - Gene count matrix
   - Sample metadata table

> **Note on raw vs. processed data:** The raw data (fastq files) is also available at `syn29390037`. Processing raw RNA-seq data requires significant computational resources and time. For this workshop we start from the processed counts, which is the typical starting point for differential expression analysis.

---

## Part 3: Analyze the Data

We will use an AI assistant (<!-- TODO: specify tool — Claude, ChatGPT, Gemini, etc. -->) alongside an analysis environment (<!-- TODO: specify — Posit Cloud, Google Colab, local R, etc. -->) to explore the data and reproduce key results from the paper.

### Step 3.1 — Set up your analysis environment

<!-- TODO: Add specific setup instructions for the chosen environment -->

1. Open <!-- TODO: environment link -->
2. Sign in with your <!-- TODO: account type --> account
3. Open the workshop notebook or create a new session

### Step 3.2 — Load the data

In your analysis environment, load the count matrix and metadata you downloaded from Synapse.

**Ask the AI assistant:** *"I have an RNA-seq count matrix and a metadata table. The counts are in a file called [filename]. How do I load this into R and check that it looks correct?"*

Pay attention to:
- How many rows (genes) and columns (samples) does the count matrix have?
- Do the sample names in the metadata match the column names in the count matrix?

### Step 3.3 — Normalize the data and run a PCA

RNA-seq counts must be normalized before samples can be compared. The paper used **TMM normalization** (Trimmed Mean of M-values) via the edgeR package.

**Ask the AI assistant:** *"How do I normalize RNA-seq count data using TMM normalization in R with edgeR? I have 14 samples: 7 primary Schwann cell cultures and 7 immortalized Schwann cell lines."*

After normalizing:
1. Run a PCA on the normalized data
2. Color the points by condition (primary vs. immortalized)

**What to look for:** Your PCA should look similar to **Figure 5A** in the paper. The two groups should separate, mostly along PC1 or PC2.

**Discussion question:** What does it mean if two samples that are supposed to be a "matched pair" (same donor, primary vs. immortalized) cluster closer together than two different donors in the same condition?

### Step 3.4 — Identify differentially expressed genes

Differential expression (DE) analysis asks: which genes are expressed at significantly different levels between the two conditions?

The paper used **limma + voom** with a paired design (each immortalized line is matched to its primary culture from the same donor).

**Ask the AI assistant:** *"I want to do a paired differential expression analysis comparing immortalized vs. primary conditions using limma-voom in R. I have 7 matched pairs. How do I set up the design matrix to account for the pairing?"*

Apply the significance thresholds used in the paper:
- BH-adjusted p-value < 0.05
- |log2 fold change| > 2

How many genes pass these thresholds? Compare your number to the **993 DEGs** reported in the paper.

### Step 3.5 — Make a volcano plot

A volcano plot shows fold change (x-axis) against statistical significance (y-axis) for every gene tested.

**Ask the AI assistant:** *"How do I make a volcano plot in R using ggplot2? I want to color genes that are significantly up-regulated in immortalized cells in blue and significantly up-regulated in primary cells in red."*

Your plot should resemble **Figure 5B** from the paper.

**Discussion question:** Locate *NF1* on your volcano plot. Where does it fall? Is it significantly different between conditions? Why does this matter?

### Step 3.6 — Check Schwann cell marker genes

The researchers needed to confirm that the immortalized cells still behave like Schwann cells. Look up the expression of these key marker genes in your data:

- **S100B** — a canonical Schwann cell marker
- **MPZ** (myelin protein zero) — Schwann cell identity
- **CDK4** — the mCdk4 transgene introduced during immortalization (should be high in immortalized cells)
- **hTERT (TERT)** — the telomerase transgene (should be high in immortalized cells)

**Ask the AI assistant:** *"How do I extract and plot the normalized expression values for a specific list of genes across all 14 samples?"*

### Step 3.7 — Run pathway enrichment analysis

With the list of 993 DEGs, we can ask: what biological processes are most affected by immortalization?

The paper used **g:Profiler** (gprofiler2 in R) to find enriched Gene Ontology terms, KEGG pathways, and Reactome pathways.

**Ask the AI assistant:** *"I have a list of differentially expressed gene symbols. How do I run pathway enrichment analysis using the gprofiler2 R package?"*

Run enrichment separately for:
- Genes **up-regulated** in immortalized cells
- Genes **up-regulated** in primary cells

**What to expect:** Genes up-regulated in immortalized cells should enrich for **cell cycle** pathways — this is expected because mCdk4 drives cell division. Compare your top enriched terms to **Figure 5D** in the paper.

---

## Part 4: Interpret and Discuss

### Key questions to consider

1. The immortalized cell lines were created as a research tool for studying cNF. Based on the RNA-seq data, do they appear to retain the essential features of the original tumor cells? What evidence supports your answer?

2. The paper identifies hundreds of genes that change during immortalization. Does this concern you as a researcher who wants to use these lines to study NF1 biology? Why or why not?

3. How did using the AI assistant change how you worked through this analysis? What kinds of questions was it most helpful for?

### Bonus exercises

- Look up the expression of genes involved in the **RAS/MAPK signaling pathway** (KRAS, HRAS, MAP2K1, MAPK1). Are any of these differentially expressed?
- The paper also generated WES and WGS data for these cell lines. Navigate the Synapse collection and find where that data lives. What kinds of files are available?
- Find the analysis code for this paper on GitHub: [https://github.com/nf-osi/cnf-cell-lines](https://github.com/nf-osi/cnf-cell-lines). Compare the approach in the code to what you did in this workshop.

---

[← Back to Track 2 overview](README.md) | [← Back to workshop home](../README.md)
