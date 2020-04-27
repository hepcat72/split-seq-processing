#!/usr/bin/env bash

#USAGE: ./splitseq_run.sh run1 mrna.fq bcumi.fq v1 reference_directory "sample_name A1:B6" "sample2_name B7:C12" ...

set -euxo pipefail

all_args=("$@")

run_id=$1
mrna_fq=$2
bcumi_fq=$3
chemistry=$4  #v1 or v2
ssrefdir=$5
raw_samples=("${all_args[@]:5}")


#Build the sample arguments, e.g. `--sample name A1:B6 --sample B7:C12`
sample_args=""
if [ $# -gt 5 ]; then
  for n in "${raw_samples[@]}"
    do
      #Allow samples' wells string to be a single well
      if [ `echo "${n}" | cut -d ' ' -f 2 | grep -c -E '[-:]'` -eq 0 ]; then
        name=`echo "${n}" | cut -d ' ' -f 1`
        well=`echo "${n}" | cut -d ' ' -f 2`
        n="$name ${well}-${well}"
      fi
      sample_args="${sample_args} --sample ${n}"
    done
fi

mkdir "${run_id}"

split-seq all \
    --fq1 "${mrna_fq}" \
    --fq2 "${bcumi_fq}" \
    --output_dir "${run_id}" \
    --chemistry "${chemistry}" \
    --genome_dir "${ssrefdir}" \
    --nthreads 16 \
    ${sample_args}

echo
echo Done.
echo "Output library (to supply to split-seq combine) is:"
echo "${run_id}"
