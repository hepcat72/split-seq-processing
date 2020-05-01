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

#Allow the sample's wells string to be a single well
if [ `echo "${sample_wells}" | cut -d ' ' -f 2 | grep -c -E '[-:]'` -eq 0 ]; then
  name=`echo "${sample_wells}" | cut -d ' ' -f 1`
  well=`echo "${sample_wells}" | cut -d ' ' -f 2`
  sample_wells="$name ${well}-${well}"
fi

mkdir "${run_id}"

split-seq combine \
    --output_dir "${run_id}" \
    --sublibraries ${libdirs} \
    --chemistry "${chemistry}" \
    --genome_dir "${ssrefdir}" \
    --sample ${sample_wells}

cd "${run_id}"

for s in *DGE_{,un}filtered
  do
    sparse2dense.pl --verbose \
        -i "$s/DGE.mtx" \
        -g "$s/genes.csv" \
        -c "$s/cell_metadata.csv" \
        -a "../${ssrefdir}/genes.gtf" \
        -o "$s/DGE.tsv"
  done

echo
echo Done.
echo "Output sample is located in:"
echo "${run_id}"
