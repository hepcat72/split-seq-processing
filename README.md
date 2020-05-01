# split-seq-processing

Robert W. Leach

## Overview

The scripts contained in this package are for running and post-processing [SplitBio](https://www.splitbiosciences.com/) sequencing libraries.  SplitBio libraries require specialized analysis using [SPLiT-Seq software](https://sites.google.com/uw.edu/splitseq/).

This package contains scripts for both performing and post-processing the SPLiT-Seq pipeline, including a sample script for loading output in Seurat (both locally in R and via galaxy/tools-iuc/seurat).

These split-seq processing scripts run on sequencing data that has been initially demultiplexed using standard Illumina i7 indexing barcodes, e.g. via `bcl2fastq`, which processes 3 files:

>    * `I1`: Read 2: Sample index read (i7, optional)
>    * `R1`: Read 1: 66 nt mRNA reads
>    * `R2`: Read 4: 94 nt reads containing UMI and barcodes
>
>    | Read Number            | Split Read Type |
>    |------------------------|-----------------|
>    | Read 1 - Forward Read  | `R1`            |
>    | Read 2 - I7 Index      | `I1`            |
>    | Read 3 - I5 Index      | `NA`            |
>    | Read 4 - Reverse Read  | `R2`            | 

Split-seq wrapper scripts for processing the output of Illumina demultiplexing:

- splitseq_mkref.sh - make a reference (from 1 or more fasta files)
- splitseq_run.sh - single cell demultiplexing
- splitseq_combine.sh - combine separate sequencing runs to build sample(s)

These scripts must be run using the conda environment created in the install procedure below.  The `run` and `mkref` should be configured to use 16 threads and they need a large amount of memory, depending on the reference size.  For a human/mouse combo, these parameters worked well in our testing on a SLURM cluster:

- `--ntasks-per-node 16`
- `--mem 228000`

## Install / Setup

### This Repo

This repo contains the details necessary to install the split-seq-pipeline's dependencies and scripts to both run the split-seq-pipeline and post-process its output.

To install this module type the following:

    git clone https://github.com/hepcat72/split-seq-processing.git
    cd split-seq-processing
    perl Makefile.PL
    make
    make install

Optional:

    make clean

You may need to either open a new terminal session or run the following before the executables will be recognized as being in your PATH:

- `hash -r` (bash)
- `rehash` (tcsh)

### SPLiT-Seq

#### Create & activate the conda environment:

To prepare the split-seq-pipeline dependencies (if you haven't already installed the split-seq-pipeline), you will need [conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html#regular-installation).  [Conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html#regular-installation) is a platform-independent package manager.  Using [conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html#regular-installation) to install the dependencies will make the install of SPLiT-Seq much easier.

    conda env create -f split-seq-processing/cfg/environment.yml
    conda activate splitseq

#### Install split-seq-pipeline:

By activating the splitseq conda environment (above), the installation of the split-seq-pipeline package will happen inside the conda environment.  (Note, you will have to do this anytime you want to perform a split-seq analysis.)

    git clone https://github.com/yjzhang/split-seq-pipeline.git
    cd split-seq-pipeline
    export HTSLIB_CONFIGURE_OPTIONS=--disable-bz2
    pip install -e .

## Creating References

An example dual reference creation:

    wget ftp://ftp.ensembl.org/pub/release-93/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
    wget ftp://ftp.ensembl.org/pub/release-93/fasta/mus_musculus/dna/Mus_musculus.GRCm38.dna.primary_assembly.fa.gz
    wget ftp://ftp.ensembl.org/pub/release-93/gtf/homo_sapiens/Homo_sapiens.GRCh38.93.gtf.gz`
    wget ftp://ftp.ensembl.org/pub/release-93/gtf/mus_musculus/Mus_musculus.GRCm38.93.gtf.gz

    gunzip Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
    gunzip Mus_musculus.GRCm38.dna.primary_assembly.fa.gz
    gunzip Homo_sapiens.GRCh38.93.gtf.gz
    gunzip Mus_musculus.GRCm38.93.gtf.gz

    conda activate splitseq
    splitseq_mkref.sh "hg38 mm10" "Homo_sapiens.GRCh38.dna.primary_assembly.fa Mus_musculus.GRCm38.dna.primary_assembly.fa" "Homo_sapiens.GRCh38.93.gtf Mus_musculus.GRCm38.93.gtf"

A dual reference (human and mouse) is created in a single directory in the current working directory named using a join of the genome names delimited by underscores.

## Analysis

### Overview

SPLiT-Seq sequencing via an Illumina sequencer is typically done in multiple runs and produces 3 files each time:

1. Forward (mRNA reads (66 nt))
2. Reverse (reads contain UMI and barcodes (94 nt))
3. Index (i7)

There are 4 phases in the overall analysis:

1. Build a reference
2. Standard Illumina demultiplexing *(not described in this workflow)*
3. Split-seq cell demultiplexing
4. Combine sample data across multiple sequencing runs (skip if only 1 sequencing run was performed)

Some post-processing is included in the shell script (`splitseq_run.sh`) used in this workflow.  The final sample output can be further analyzed using Seurat.  We have provided the R code necessary to create a Seurat object and the `DGE.tsv` file produced in each sample directory can be supplied to the Galaxy/tools-iuc/Seurat tool.

### Workflow

#### Build a reference

    splitseq_mkref.sh "genome names" "fasta files" "gtf files"

Each of the 3 parameters can contain multiple space-delimited values wrapped in quotes (in order to align to multiple genomes at once).  Example: `splitseq_mkref.sh "hg38 mm10" "human.fa mouse.fa" "human.gtf mouse.gtf"`

The genome names are joined with delimiting underscores and an output directory is created in the splitseq_refs subdirectory.

#### Cell Demultiplexing

Sample demultiplexing the data off the sequencer with the index file happens per run as usual.  The cell-level demultiplexing is done after that standard i7 Illumina demultiplexing as follows.

    conda activate splitseq
    splitseq_run.sh run_id read1.fastq.gz read2.fastq.gz chemistry reference_directory "sample_name sample_wells"

Note that only gzipped fastq files are permitted.  Parameters are as follows

- `chemistry` (for all intents and purposes) should always be "v1".  The chemistry indicates the pre-made set of cell barcodes, which are embedded in the split-seq-pipeline, so that the barcodes do not have to be specified manually.
- `reference_directory` is the output directory of the `split-seq mkref` command.
- `sample_name` can be any alpha-numeric value with underscores.
- `sample_wells` is a well name range specified by 2 well names separated by a colon or dash, which means different ranges of wells, e.g. "A1:B6" indicates wells A1-A6 and B1-B6 whereas "A1-B6" indicates wells A1-A12 and B1-B6.  Individual wells and multiple ranges can be specified, separated by commas, e.g. "A1:B6,B8:B12,C3".  Example: `splitseq_run.sh run1 mrna.fastq.gz bcumi.fastq.gz v1 hg38_mm10 "sample1 A1:B6"`

#### Combine multiple sequencing runs

Multiple sequencing runs containing portions of the same sample(s) must be merged into a single sample file.

    conda activate splitseq
    splitseq_combine.sh run_id chemistry reference_directory splitseq_all_seq_run_directories "sample_name sample_wells"

- `chemistry` (for all intents and purposes) should always be "v1".  The chemistry indicates the pre-made set of cell barcodes, which are embedded in the split-seq-pipeline, so that the barcodes do not have to be specified manually.
- `reference_directory` is the output directory of the `split-seq mkref` command.
- `splitseq_all_seq_run_directories` are the output directories of the various `split-seq all` runs, one for each sequencing run.
- `sample_name` can be any alpha-numeric value with underscores.
- `sample_wells` is a well name range specified by 2 well names separated by a colon or dash, which means different ranges of wells, e.g. "A1:B6" indicates wells A1-A6 and B1-B6 whereas "A1-B6" indicates wells A1-A12 and B1-B6.  Individual wells and multiple ranges can be specified, separated by commas, e.g. "A1:B6,B8:B12,C3".  Example: `splitseq_combine.sh run1 v1 hg38_mm10 "sample1 A1:B6"`

## LICENCE

See `LICENSE`
