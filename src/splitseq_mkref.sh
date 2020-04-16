#!/usr/bin/env bash

#USAGE: ./splitseq_mkref.sh "genome names" "fasta files" "gtf files"

set -euxo pipefail

genome_names=$1  #space-delimited, e.g. "hg38 mm10"
fastas=$2        #space-delimited, e.g. "hg38.fa mm10.fa"
gtfs=$3          #space-delimited, e.g. "hg38.gtf mm10.gtf"

refdir=`echo "${genome_names}" | perl -pne 's/ /_/g;'`

mkdir "${refdir}"

split-seq mkref \
    --genome ${genome_names} \
    --fasta ${fastas} \
    --genes ${gtfs} \
    --output_dir "${refdir}" \
    --nthreads 16

echo
echo Done.
echo "Output reference (to supply to split-seq all) is:"
echo "${refdir}"
