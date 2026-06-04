# Step-by-step instructions: Analyzing NF Portal Datasets in Pluto

---

## Step 1: Accept your Pluto invitation
If you have requested Pluto access prior to the workshop, you will receive a Pluto invitation email. Clicking accept invitation will take you to a page to sign up for your temporary 30-day Pluto account. 
Enter your email and a secure password. Choose the sign up option and enter your full name and email to create your account. Finally, accept the invitation to join the CTF Pluto workspace. 

Congratulations! You are now ready to analyze data in Pluto.

## Step 2: Navigate to the Published data sets
You are now in the Pluto workspace. The workspace contains all of your projects, experiments (datasets), and analyses. You can also access CTF-curated published data sets from the workspace, including the sample metadata, counts data, and existing analyses. 

Multiple experiments can be organized into project folders and shared at the experiment level or the project level. Analyses are associated with individual experiments or, in the case of a multi-omics experiment, a group of linked experiments. 

If you want to find CTF's curated project full of NF datasets, go to the project entitled "CTF NF Target Discovery Hub - External" from the Workspace page or the analysis tab in the left-hand menu of the page. To find the dataset for today's data workshop, go to the left-hand menu and select Research. 

The first option is Published data sets. Select this option to browse the public experiments from Synapse, GEO, and other public data repositories. 

## Step 3: Find a specific NF dataset
In this workshop, we will be using a specific public dataset from the NF Data Portal. Go to the search bar for the public data sets page. Type "synodos" and hit enter to start filtering datasets for this keyword.
Choose the resulting dataset entitled "Human NF1 Low Grade Glioma RNAseq Data" to open the experiment. 

## Step 4: Run a differential expression analysis 
This experiment has already been processed through an nf-core pipeline, so the raw counts are available. You can view the counts data along with the sample metadata table and the pipeline QC results in the area below the experiment notebook. 
In order to start a no-code analysis on this dataset, go to the Analysis tab (next to Overview) and select the Grid option to open the analysis grid. Existing analysis are already available to preview. 

Select the exploratory analysis button to open the analysis catalog. Here, you will see all of the no-code analysis options that are available for this experiment. You can search for a particular analysis to filter by category.
Select the differential expression analysis and hit the create analysis button. 

You will now begin customizing your own analysis. Here, you will select a variable to group your samples by for differential expression analysis. Follow along with the workshop by selecting the "Nf1 Genotype" variable. 
In the dropdown menu for experimental group, select the label "-/-" indicating homozygous deletion of *NF1*. In the In the dropdown menu for control group, select the label "+/-" indicating heterozygous deletion of *NF1*.
Click start analysis to begin running your differential expression analysis. 

Once the analysis appears, you can customize the plot filters, colors, and highlighted features by selecting the plot settings or pencil icon to the left of the plot. The significantly increased genes in the 
-/- (homozygous) group relative to the +/- (heterozygous) group have significantly positive log2 fold changes and significantly high negative log2 adjusted p-values. On the other hand, the significantly decreased
genes in the homozygous group relative to the heterozygous group have significantly *negative* log2 fold changes, and are on the left side of the x-axis. 

You can hold down click and circle a region of the plot
to lasso a group of genes. That group of genes will then be highlighted and labeled for quick reference, and named in the plot settings under "Labeled features" for reference. 

Check the results and methods tabs under the plot to find the analyses data table and methods descriptions, respectively. 

## Step 5 (optional): Run a principal component analysis (PCA)
Navigate back to the analysis catalog by exiting the differential expression analysis. Select principal components (PCA) and create analysis. Start the PCA by clicking run analysis. Once the PCA is completed, open the plot settings and 
scroll down to the Points sections where you will see all of the available variables to group these samples by in the low dimensional space created by the PCA. Select "Tumortype" and save changes to update the group coloring on the plot.

Once the colors update, check how the groups are distributed. Are they all distinct clusters or are there overlaps between multiple groups on the PCA? 

Overlapping groups may indicate that the gene expression between those groups is not highly heterogenous. Depending on the variables selected, PCA plots can also revela batch effects or outlying samples.

## Conclusion
Thank you for joining the data workshop for analyzing NF Portal Datasets on Pluto! 

Today, you have learned how to search for NF Data Portal datasets in Pluto projects or public data sets and how to run no-code analyses to generate custom data visualizations.
We have also walked through how you can explore plots more deeply through additional plot settings, results, and methods. 

To continue working in Pluto, [please contact Kara Quaid for extended access](https://www.ctf.org/pluto-web-access/). If you have any questions about
Pluto, don't hesitate to reach out the Andrew Goodspeed (andrew@pluto.bio), Mea Casey (mea@pluto.bio), or the Pluto Support team via support@pluto.bio. 


