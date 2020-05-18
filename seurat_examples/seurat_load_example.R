## Install necessary R packages (should only need to be done once) - uncomment to run
#list.of.packages <- c("dplyr","BiocManager","Seurat","patchwork")
#new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
#if(length(new.packages)) install.packages(new.packages)

# Load the libraries we will need
library(dplyr)
library(Seurat)
library(patchwork)
library(Matrix)

# Edit these values to load your sample into seurat
ss_sample_dir <- "/path/to/samplename_DGE_filtered"
mtx_filename  <- "DGE.mtx"
cell_filename <- "cell_metadata.csv"
gene_filename <- "genes.csv"
project_name  <- "example_project_name"
assay_name    <- "RNA"
min_cells     <- 3
min_features  <- 200

# 1. Set a splitseq sample directory as the working directory
setwd(ss_sample_dir)

# 2. Read in the Split-Seq sample data
ssmatrix <- t(as.matrix(readMM(mtx_file_name)))
coldata <- read.csv(file=cell_filename, header=TRUE, sep=",")
rowdata <- read.csv(file=gene_filename, header=TRUE, sep=",")

# 3. Create row and column names
rownames(ssmatrix) <- make.names(rowdata$gene_id, unique = TRUE, allow_ = FALSE)
colnames(ssmatrix) <- make.names(coldata$cell_barcode, unique = TRUE, allow_ = FALSE)

# 4. Create the Seurat object
pbmc <- CreateSeuratObject(counts = ssmatrix, min.cells = min_cells, min.features  = min_features, project = project_name, assay = assay_name)


##
## Alternative to reading the split-seq mtx data (steps 2 & 3 above), you can
## read in the "DGE.tsv" file, which (by default) includes chromosomes and gene
## symbols.
##
#
#ssmatrix <- as.matrix(read.table("DGE.tsv", sep="\t", header=TRUE))
