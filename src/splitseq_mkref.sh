#!/bin/bash

#USAGE: ./splitseq_mkref.sh "genome names" "fasta files" "gtf files"

genome_names=$1  #space-delimited, e.g. "hg38 mm10"
fastas=$2        #space-delimited, e.g. "hg38.fa mm10.fa"
gtfs=$3          #space-delimited, e.g. "hg38.gtf mm10.gtf"

splitseq_venv="/Genomics/grid/users/rleach/local/splitseq"
splitseq_refs="${splitseq_venv}/splitseq_refs"
refdir="${splitseq_refs}/"`echo "${genome_names}" | perl -pne 's/ /_/g;'`

cd "${splitseq_venv}"

mkdir "${splitseq_refs}"

set -eu

. /usr/share/Modules/init/sh

module load STAR/2.7.3a
module load samtools/1.10
module load python/3.6.4

mkdir "${refdir}"

echo ./bin/python ./bin/split-seq mkref \
    --genome ${genome_names} \
    --fasta ${fastas} \
    --genes ${gtfs} \
    --output_dir "${refdir}" \
    --nthreads 16

./bin/python ./bin/split-seq mkref \
    --genome ${genome_names} \
    --fasta ${fastas} \
    --genes ${gtfs} \
    --output_dir "${refdir}" \
    --nthreads 16

echo
echo Done.
echo "Output reference (to supply to split-seq all) is located in:"
echo "${refdir}"
