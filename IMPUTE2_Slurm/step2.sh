#!/bin/bash

workDir="$1"
softwareDir="$2"
referenceDir="$3"
fileName="$4"

if [ ! -s ${workDir}/step2 ]; then
    mkdir ${workDir}/step2
fi

if [ -f ${workDir}/step2/snps-reference ]; then
    rm -r ${workDir}/step2/snps-reference
fi
for chr in {1..22}; do
    gunzip -c\
        ${referenceDir}/1000GP_Phase3_chr${chr}.legend.gz \
    |gawk -v\
        chr=${chr} '$5=="Biallelic_SNP" && $1!="id" {print chr"_"$2}' >>\
        ${workDir}/step2/snps-reference
done

gawk '{print $1"_"$4}'\
    ${workDir}/step1/${fileName}.hg19.map >\
    ${workDir}/step2/snps-reference-and-rawdata
sort\
    ${workDir}/step2/snps-reference\
| uniq >>\
    ${workDir}/step2/snps-reference-and-rawdata
sort\
    ${workDir}/step2/snps-reference-and-rawdata\
| uniq -d |\
    gawk -F "_" '{$3=$2+1; print $1, $2, $3, "R"NR}' >\
    ${workDir}/step2/snps-reference-and-rawdata-duplicates
${softwareDir}/plink\
    --file ${workDir}/step1/${fileName}.hg19\
    --extract ${workDir}/step2/snps-reference-and-rawdata-duplicates\
    --range --make-bed --out ${workDir}/step2/${fileName}.hg19.noDuplicates

for chr in {1..22}; do
    ${softwareDir}/plink\
        --bfile ${workDir}/step2/${fileName}.hg19.noDuplicates\
        --chr $chr --make-bed\
        --out ${workDir}/step2/${fileName}.hg19.noDuplicates.chr${chr}
done
