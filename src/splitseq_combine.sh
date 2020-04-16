#!/usr/bin/env bash

#Run once for each sample to gather sequences from multiple sequencing runs that belong to that sample.  Sample name must be exactly the same as in each sequencing run.

#USAGE: ./splitseq_combine.sh run1 v1 reference_directory "splitseq_all_out_directories" "sample_name A1:B6"

set -euxo pipefail

all_args=("$@")

run_id=$1
chemistry=$2  #v1 or v2
ssrefdir=$3
libdirs="$4"
sample_wells=("${all_args[@]:4}")

mkdir "${run_id}"

split-seq combine \
    --output_dir "${run_id}" \
    --sublibraries ${libdirs} \
    --chemistry "${chemistry}" \
    --genome_dir "${ssrefdir}" \
    --sample ${sample_wells}

echo
echo Done.
echo "Output sample is located in:"
echo "${run_id}"
