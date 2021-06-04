#!/bin/bash

workDir="$1"
softwareDir="$2"
fileName="$3"
basepath="$4"

missThreshold="$5"
mafThreshold="$6"
hweThreshold="$7"
infoThreshold="$8"

if [ ! -s ${workDir}/step6 ]; then
  mkdir ${workDir}/step6
fi

if [ -f ${workDir}/step6/mergeList.txt ]; then
    rm ${workDir}/step6/mergeList.txt
fi

chunkNumHuge=1000 # set a huge value to make sure involving every chunk
for chr in {1..22}; do
    for chunk in $( seq 1 ${chunkNumHuge} ); do
        if [ -f ${workDir}/step4/${fileName}.hg19.noDuplicates.chr${chr}.phased.chunk${chunk}.impute2_info ]; then
            awk {'print $2,$7'} \
            ${workDir}/step4/${fileName}.hg19.noDuplicates.chr${chr}.phased.chunk${chunk}.impute2_info >> \
            ${workDir}/step6/${fileName}.hg19.noDuplicates.chr${chr}.phased.impute2_info
        fi
    done
    ${softwareDir}/R --slave <${basepath}/filterByInfo.R --args\
        "${infoThreshold}"\
        "${workDir}/step6/${fileName}.hg19.noDuplicates.chr${chr}.phased.impute2_info"\
        "${workDir}/step6/${fileName}.hg19.noDuplicates.chr${chr}.phased.impute2.filter.list"

    ${softwareDir}/plink \
        --bfile ${workDir}/step5/${fileName}.hg19.noDuplicates.chr${chr}.phased.impute2\
        --extract ${workDir}/step6/${fileName}.hg19.noDuplicates.chr${chr}.phased.impute2.filter.list\
        --maf ${mafThreshold}\
        --geno ${missThreshold}\
        --hwe ${hweThreshold}\
        --make-bed\
        --out ${workDir}/step6/${fileName}.hg19.noDuplicates.chr${chr}.phased.impute2.filter

     echo "${workDir}/step6/${fileName}.hg19.noDuplicates.chr${chr}.phased.impute2.filter" >> ${workDir}/step6/mergeList.txt
done

${softwareDir}/plink \
    --merge-list ${workDir}/step6/mergeList.txt\
    --make-bed\
    --out ${workDir}/step6/${fileName}.imputed\
    --allow-no-sex
