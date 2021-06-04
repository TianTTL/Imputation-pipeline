#!/bin/bash

workDir="$1"
softwareDir="$2"
referenceDir="$3"
fileName="$4"

startChr="$5"
startChunk="$6"
endChr="$7"
endChunk="$8"

# counting chunks and locating start postion for each chromosome
chunkSize=5000000
chrStartPos=(-9)
chunkCNT=(-9)
chunkCNTAll=0
for chr in {1..22}; do
    fileNameCurrent="${fileName}.hg19.noDuplicates.chr${chr}.phased"
    maxPos=$(gawk '$1!="position" {print $1}' ${referenceDir}/genetic_map_chr${chr}_combined_b37.txt\
        | sort -n | tail -n 1)
    minPos=$(gawk '$1!="position" {print $1}' ${referenceDir}/genetic_map_chr${chr}_combined_b37.txt\
        | sort -n | head -n 1)
    nrChunk=$(expr "(" ${maxPos} "-" ${minPos} "+" 1 ")" "/" ${chunkSize} "+" 1)
    chrStartPos+=($(expr ${minPos} "-" 1))
    chunkCNT+=(${nrChunk})
    chunkCNTAll=$(expr ${chunkCNTAll} + ${nrChunk})
done
for chr in $( seq ${startChr} ${endChr} ); do
    for chunk in $( seq 1 ${chunkCNT[${chr}]} ); do
        if [[ ${chr} -eq ${startChr} ]] && [[ ${chunk} -lt ${startChunk} ]]; then
            continue
        elif [[ ( ${chr} -gt ${endChr} ) ]] || { [[ ${chr} -eq ${endChr} ]] && [[ ${chunk} -gt ${endChunk} ]] ;}; then
            break 2
        else
            fileNameCurrent="${fileName}.hg19.noDuplicates.chr${chr}.phased"
            chunkStartPos=$(expr ${chrStartPos[${chr}]} + \( ${chunk} - 1 \) \* ${chunkSize})
            chunkEndPos=$(expr ${chunkStartPos} + ${chunkSize})
            ${softwareDir}/impute2\
                -use_prephased_g\
                -known_haps_g ${workDir}/step3/${fileNameCurrent}.haps\
                -m ${referenceDir}/genetic_map_chr${chr}_combined_b37.txt\
                -h ${referenceDir}/1000GP_Phase3_chr${chr}.hap.gz\
                -l ${referenceDir}/1000GP_Phase3_chr${chr}.legend.gz\
                -int ${chunkStartPos} ${chunkEndPos} -Ne 20000\
                -o ${workDir}/step4/${fileNameCurrent}.chunk${chunk}.impute2\
                -k_hap 500
            if [ -f "${workDir}/step4/${fileNameCurrent}.chunk${chunk}.impute2_info" ]; then
                ${softwareDir}/plink \
                --gen ${workDir}/step4/${fileNameCurrent}.chunk${chunk}.impute2 \
                --sample ${workDir}/step3/${fileNameCurrent}.sample \
                --oxford-single-chr ${chr} \
                --make-bed --out ${workDir}/step4/${fileNameCurrent}.chunk${chunk}.impute2 \
                --allow-no-sex
            fi
        fi
    done
done