#!/bin/bash

#Run once for each sample to gather sequences from multiple sequencing runs that belong to that sample.  Sample name must be exactly the same as in each sequencing run.

#USAGE: ./splitseq_combine.sh run1 v1 reference_directory "splitseq_all_out_directories" "sample_name A1:B6"

all_args=("$@")

run_id=$1
chemistry=$2  #v1 or v2
ssrefdir=$3
libdirs="$4"
sample_wells=("${all_args[@]:4}")

splitseq_venv="/Genomics/grid/users/rleach/local/splitseq"
splitseq_runs="${splitseq_venv}/splitseq_runs"

cd "${splitseq_venv}"

mkdir "${splitseq_runs}"

set -eu

. /usr/share/Modules/init/sh

module load STAR/2.7.3a
module load samtools/1.10
module load python/3.6.4

mkdir "${splitseq_runs}/${run_id}"

echo ./bin/python ./bin/split-seq combine \
    --output_dir "${splitseq_runs}/${run_id}" \
    --sublibraries ${libdirs} \
    --chemistry "${chemistry}" \
    --genome_dir "${ssrefdir}" \
    --sample ${sample_wells}

./bin/python ./bin/split-seq combine \
    --output_dir "${splitseq_runs}/${run_id}" \
    --sublibraries ${libdirs} \
    --chemistry "${chemistry}" \
    --genome_dir "${ssrefdir}" \
    --sample ${sample_wells}

echo
echo Done.
echo "Output sample is located in:"
echo "${splitseq_runs}/${run_id}"
