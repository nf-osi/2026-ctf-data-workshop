# Track 2 Instructions: Using AI to Analyze cNF RNA-seq Data

## Before You Start

Make sure you have:
- A laptop with Chrome or Firefox
- Logged in to your [Synapse account](https://www.synapse.org) — if you don't have one, see [SETUP.md](../SETUP.md)
- Completed the [Track 2 software setup](setup.md) — R, Node.js, and Claude Code must be installed and your API key must be set

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

Your analysis environment is **Claude Code running in a terminal alongside R**. Claude Code is an AI assistant that can write R scripts, run them, interpret error messages, and explain results — all from the command line. You direct the analysis in plain English; Claude Code does the coding.

### Step 3.1 — Start Claude Code

1. Open a terminal and navigate to your workshop directory:
   ```
   cd nf-workshop
   ```
2. Start Claude Code:
   ```
   claude
   ```
3. You should see the Claude Code prompt. You are now ready to analyze data.

> **How this works:** You type a request in plain English. Claude Code writes an R script, runs it with `Rscript`, and shows you the output. You can ask follow-up questions, request changes, or ask Claude Code to explain what the code is doing at any point.

### Step 3.2 — Load the data

Move the files you downloaded from Synapse into your `nf-workshop` folder, then ask Claude Code:

**Prompt:** *"I have RNA-seq data from a study of NF1 cutaneous neurofibroma Schwann cells. The count matrix file is called [filename] and the metadata file is called [filename]. Please write an R script to load both files, check that the sample names match between them, and print the dimensions of the count matrix."*

Pay attention to:
- How many rows (genes) and columns (samples) does the count matrix have?
- Do the sample names in the metadata match the column names in the count matrix?

Pay attention to:
- How many rows (genes) and columns (samples) does the count matrix have?
- Do the sample names in the metadata match the column names in the count matrix?

### Step 3.3 — Normalize the data and run a PCA

RNA-seq counts must be normalized before samples can be compared. The paper used **TMM normalization** (Trimmed Mean of M-values) via the edgeR package.

**Prompt:** *"Using the count matrix we just loaded, normalize the data using TMM normalization with the edgeR package. I have 14 samples: 7 primary Schwann cell cultures and 7 immortalized Schwann cell lines. After normalizing, run a PCA and save a plot colored by condition (primary vs. immortalized) as pca.pdf."*

After normalizing:
1. Run a PCA on the normalized data
2. Color the points by condition (primary vs. immortalized)

**What to look for:** Your PCA should look similar to **Figure 5A** in the paper. The two groups should separate, mostly along PC1 or PC2.

**Discussion question:** What does it mean if two samples that are supposed to be a "matched pair" (same donor, primary vs. immortalized) cluster closer together than two different donors in the same condition?

### Step 3.4 — Identify differentially expressed genes

Differential expression (DE) analysis asks: which genes are expressed at significantly different levels between the two conditions?

The paper used **limma + voom** with a paired design (each immortalized line is matched to its primary culture from the same donor).

**Prompt:** *"Now run a paired differential expression analysis comparing immortalized vs. primary conditions using limma-voom in R. I have 7 matched pairs — each immortalized line has a matched primary culture from the same donor. Set up the design matrix to account for the pairing, then apply a significance threshold of BH-adjusted p-value < 0.05 and absolute log2 fold change > 2. Save the full results table as de_results.csv and print a summary of how many genes are significant."*

Apply the significance thresholds used in the paper:
- BH-adjusted p-value < 0.05
- |log2 fold change| > 2

How many genes pass these thresholds? Compare your number to the **993 DEGs** reported in the paper.

### Step 3.5 — Make a volcano plot

A volcano plot shows fold change (x-axis) against statistical significance (y-axis) for every gene tested.

**Prompt:** *"Using the DE results table, make a volcano plot with ggplot2. Color genes significantly up-regulated in immortalized cells blue, genes significantly up-regulated in primary cells red, and non-significant genes grey. Label the NF1 gene on the plot. Save it as volcano.pdf."*

Your plot should resemble **Figure 5B** from the paper.

**Discussion question:** Locate *NF1* on your volcano plot. Where does it fall? Is it significantly different between conditions? Why does this matter?

### Step 3.6 — Check Schwann cell marker genes

The researchers needed to confirm that the immortalized cells still behave like Schwann cells. Look up the expression of these key marker genes in your data:

- **S100B** — a canonical Schwann cell marker
- **MPZ** (myelin protein zero) — Schwann cell identity
- **CDK4** — the mCdk4 transgene introduced during immortalization (should be high in immortalized cells)
- **hTERT (TERT)** — the telomerase transgene (should be high in immortalized cells)

**Prompt:** *"From the normalized data, extract the expression values for S100B, MPZ, CDK4, and TERT across all 14 samples. Make a dot plot or bar chart showing expression by sample, colored by condition (primary vs. immortalized). Save it as marker_genes.pdf."*

### Step 3.7 — Run pathway enrichment analysis

With the list of 993 DEGs, we can ask: what biological processes are most affected by immortalization?

The paper used **g:Profiler** (gprofiler2 in R) to find enriched Gene Ontology terms, KEGG pathways, and Reactome pathways.

**Prompt:** *"Using the gprofiler2 R package, run pathway enrichment analysis on the differentially expressed genes. Run it separately for genes up-regulated in immortalized cells and genes up-regulated in primary cells. Query Gene Ontology, KEGG, and Reactome. Print the top 10 enriched terms for each group and save the full results as pathway_results.csv."*

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
