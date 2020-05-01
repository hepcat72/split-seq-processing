##
## Suggestions for QC filtering
##

# After loading your split-seq data (see seurat_load_example.R), you should
# filter your cell data.  Gene expression of damaged cells tend to be erratic,
# but one commonality is high expression levels of mitochondrial genes.  If you
# create a file containing (on each line - no header) the gene_ids of all of the
# mitochondrial genes found in your genes.gtf file (located in your reference
# directory), and name it 'mito_genes.csv', and save it in the current
# (ss_sample_dir) directory, you can run the following to cull damaged cells
# from your seurat object.  You can also set a min and max number of expressed
# genes per cell.  Use -Inf or Inf to specify no min or max.

mito_filename <- "mito_geneids.csv"
max_mito_pct  <- 0.5
min_expressed_genes_per_cell <- 200
max_expressed_genes_per_cell <- 2500

# 1. Read in and validate the mitochondrial gene IDs
mitodata   <- read.csv(file=mito_filename, header=FALSE, sep=",")
mitonames  <- make.names(mitodata$V1, unique = TRUE, allow_ = FALSE)
mito.genes <- intersect(mitonames,rownames(pbmc@assays[[assay_name]]))

# 2. Characterize, add, and display the mitochondrial data in your seurat object
percent.mito <- Matrix::colSums(pbmc@assays[[assay_name]][mito.genes, ])/Matrix::colSums(pbmc@assays[[assay_name]])
pbmc <- AddMetaData(object = pbmc, metadata = percent.mito, col.name = "percent.mito") 
VlnPlot(object = pbmc, features = c("nFeature_RNA", "nCount_RNA", "percent.mito"), ncol = 3)

# 3. Cull the damaged cells from your
pbmc <- subset(x = pbmc, subset = nFeature_RNA > min_expressed_genes_per_cell & nFeature_RNA < max_expressed_genes_per_cell & percent.mito < max_mito_pct )


##
## If you used the alternative approach of reading the DGE.tsv file in
## seurat_load_example.R, the above will only work if you construct your
## gene_ids using the first column of the DGE.tsv file.
##
## Alternatively, instead of step 1 above, since your row names will include the
## mitochondrial chromosome, you can subset by matching the row names.
##
#
#mito_pattern <- "^(hg38.MT|mm10.MT)"
#assay_name   <- "RNA"
#
#mito.genes <- grep(pattern = mito_pattern, x = rownames(pbmc@assays[[assay_name]]), value = TRUE)

