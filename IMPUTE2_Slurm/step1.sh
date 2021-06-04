#!/bin/bash

workDir="$1"
dataDir="$2"
softwareDir="$3"
liftOverReferDir="$4"
sourceBuild="$5"
fileName="$6"

indMissThreshold="$7"
snpMissThreshold="$8"
mafThreshold="$9"
hweThreshold="${10}"

if [ ! -s ${workDir}/step1 ]; then
  mkdir ${workDir}/step1
fi

# QC
if [ -f ${dataDir}/${fileName}.bed ]; then
    ${softwareDir}/plink \
     --bfile ${dataDir}/${fileName}\
     --maf ${mafThreshold} --geno ${snpMissThreshold} --mind ${indMissThreshold} --hwe ${hweThreshold}\
     --recode --out ${workDir}/step1/${fileName}
elif [ -f ${dataDir}/${fileName}.ped ]; then
    ${softwareDir}/plink \
     --file ${dataDir}/${fileName}\
     --maf ${mafThreshold} --geno ${snpMissThreshold} --mind ${indMissThreshold} --hwe ${hweThreshold}\
     --recode --out ${workDir}/step1/${fileName}
elif [ -f ${dataDir}/${fileName}.tped ]; then
    ${softwareDir}/plink \
     --tfile ${dataDir}/${fileName}\
     --maf ${mafThreshold} --geno ${snpMissThreshold} --mind ${indMissThreshold} --hwe ${hweThreshold}
     --recode --out ${workDir}/step1/${fileName}
fi

# liftOver
if [ ! ${sourceBuild} == 'hg19' ]; then
    gawk '{print "chr"$1, $4, $4+1, $2}' OFS="\t"\
        ${workDir}/step1/${fileName}.map\
        > ${workDir}/step1/${fileName}.BED

    ${softwareDir}/liftOver -bedPlus=4\
        ${workDir}/step1/${fileName}.BED\
        ${liftOverReferDir}/${sourceBuild}ToHg19.over.chain\
        ${workDir}/step1/${fileName}.hg19.BED\
        ${workDir}/step1/${fileName}.unmapped.txt

    gawk '/^[^#]/ {print $4}'\
        ${workDir}/step1/${fileName}.unmapped.txt\
        > ${workDir}/step1/${fileName}.unmappedSNPs.txt

    gawk '{print $4, $2}' OFS="\t"\
        ${workDir}/step1/${fileName}.hg19.BED\
        > ${workDir}/step1/${fileName}.hg19.mapping.txt

    ${softwareDir}/plink \
        --file ${workDir}/step1/${fileName}\
        --exclude ${workDir}/step1/${fileName}.unmappedSNPs.txt\
        --update-map ${workDir}/step1/${fileName}.hg19.mapping.txt\
        --make-bed --out ${workDir}/step1/${fileName}.hg19
    ${softwareDir}/plink \
        --bfile ${workDir}/step1/${fileName}.hg19\
        --recode --out ${workDir}/step1/${fileName}.hg19
else
    mv ${workDir}/step1/${fileName}.ped ${workDir}/step1/${fileName}.hg19.ped
    mv ${workDir}/step1/${fileName}.map ${workDir}/step1/${fileName}.hg19.map
fi

# remove snps in same position
${softwareDir}/plink \
    --file ${workDir}/step1/${fileName}.hg19 \
    --list-duplicate-vars ids-only \
    --out ${workDir}/step1/${fileName}.hg19

${softwareDir}/plink \
    --file ${workDir}/step1/${fileName}.hg19 \
    --exclude ${workDir}/step1/${fileName}.hg19.dupvar \
    --recode --out ${workDir}/step1/${fileName}.hg19
