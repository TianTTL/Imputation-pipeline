#!/bin/bash

workDir="$1"
softwareDir="$2"
fileName="$3"

if [ ! -s ${workDir}/step5 ]; then
  mkdir ${workDir}/step5
fi

chunkNumHuge=1000 # set a huge value to make sure involving every chunk
for chr in {1..22}; do
    if [ -f ${workDir}/step5/fileNeedMergeChr${chr} ]; then
        rm ${workDir}/step5/fileNeedMergeChr${chr}
    fi
    for chunk in $( seq 1 ${chunkNumHuge} ); do
       if [ -f ${workDir}/step4/${fileName}.hg19.noDuplicates.chr${chr}.phased.chunk${chunk}.impute2.bed ]; then
            echo "${workDir}/step4/${fileName}.hg19.noDuplicates.chr${chr}.phased.chunk${chunk}.impute2"\
            >> ${workDir}/step5/fileNeedMergeChr${chr}
        fi
    done

    srun \
        -p v6_384 -n 1 -c 1 --mem=10gb -t 20 -J s5_${chr} \
        ${softwareDir}/plink \
            --merge-list ${workDir}/step5/fileNeedMergeChr${chr} \
            --make-bed --out ${workDir}/step5/${fileName}.hg19.noDuplicates.chr${chr}.phased.impute2 \
            --allow-no-sex \
            --allow-no-vars&
done

wait