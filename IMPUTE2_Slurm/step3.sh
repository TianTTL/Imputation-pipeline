#!/bin/bash

workDir="$1"
softwareDir="$2"
referenceDir="$3"
fileName="$4"
threads="$5"

if [ ! -s ${workDir}/step3 ]; then
  mkdir ${workDir}/step3
fi
    
for chr in {1..22}; do
    fileNameCurrent="${fileName}.hg19.noDuplicates.chr${chr}"
    srun \
        -p v6_384 -n 1 -c $threads --mem=3gb -t 10:00:00 -J s3_${chr} \
        ${softwareDir}/shapeit\
            --input-bed ${workDir}/step2/${fileNameCurrent}.bed ${workDir}/step2/${fileNameCurrent}.bim ${workDir}/step2/${fileNameCurrent}.fam \
            --input-map ${referenceDir}/genetic_map_chr${chr}_combined_b37.txt \
            --output-max ${workDir}/step3/${fileNameCurrent}.phased \
            --thread ${threads} --output-log ${workDir}/step3/${fileNameCurrent}.phased \
            --force &
done
wait