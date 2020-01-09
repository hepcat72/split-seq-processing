#!/bin/bash

#USAGE: ./splitseq_run.sh run1 mrna.fq bcumi.fq v1 reference_directory "sample_name A1:B6" "sample2_name B7:C12" ...

all_args=("$@")

run_id=$1
mrna_fq=$2
bcumi_fq=$3
chemistry=$4  #v1 or v2
ssrefdir=$5
raw_samples=("${all_args[@]:5}")


#Build the sample arguments, e.g. `--sample name A1:B6 --sample B7:C12`
sample_args=""
for n in "${raw_samples[@]}"
  do
    sample_args="${sample_args} --sample ${n}"
  done

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

echo ./bin/python ./bin/split-seq all \
    --fq1 "${mrna_fq}" \
    --fq2 "${bcumi_fq}" \
    --output_dir "${splitseq_runs}/${run_id}" \
    --chemistry "${chemistry}" \
    --genome_dir "${ssrefdir}" \
    --nthreads 16 \
    ${sample_args}

./bin/python ./bin/split-seq all \
    --fq1 "${mrna_fq}" \
    --fq2 "${bcumi_fq}" \
    --output_dir "${splitseq_runs}/${run_id}" \
    --chemistry "${chemistry}" \
    --genome_dir "${ssrefdir}" \
    --nthreads 16 \
    ${sample_args}

echo
echo Done.
echo "Output library (to supply to split-seq combine) is located in:"
echo "${splitseq_runs}/${run_id}"
