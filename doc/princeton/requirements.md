# Splitseq Sample Processing Requirements

## Data Process

1.	User requests split-seq sequencing via iLab
2.	Data is deposited in HTSeq
3.	HTSeq does automatic standard i7 barcode demultiplexing (of forward & reverse fastq)
4.	User requests split-seq analysis & one of us (Rob) meets with them to get details (reference(s), annotations, sample name(s), and starting well IDs for each sample) and describe the analysis steps & what to expect
5.	Run the split-seq pipeline (mkref, analysis, & combine (if samples were spread across multiple runs or lanes)) on the cluster using the shell scripts
6.	Run standard Seurat pipeline (e.g. galaxy seurat tool)
7.	Send results to user and have follow up meeting to describe results, answerquestions, and advise on how to proceed from there.

## User Deliverables

- All Split-Seq pipeline outputs
- Converted mtx to tsv counts table (containing seurat-safe row/col names)
- Basic Seurat results
- Galaxy workflow
- Example Seurat script & install instructions

