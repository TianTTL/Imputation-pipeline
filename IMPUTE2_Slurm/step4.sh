#!/bin/bash

workDir="$1"
softwareDir="$2"
referenceDir="$3"
fileName="$4"
IMPUTE2threads="$5"
basepath="$6"

if [ ! -s ${workDir}/step4 ]; then
  mkdir ${workDir}/step4
fi

# counting chunks and locating start postion for each chromosome
# set a placeholder to make index start from 1
chunkSize=5000000
chrStartPos=(-9)
chunkCNT=(-9)
chunkCNTAll=0
for chr in {1..22}; do
    maxPos=$(gawk '$1!="position" {print $1}' ${referenceDir}/genetic_map_chr${chr}_combined_b37.txt\
        | sort -n | tail -n 1)
    minPos=$(gawk '$1!="position" {print $1}' ${referenceDir}/genetic_map_chr${chr}_combined_b37.txt\
        | sort -n | head -n 1)
    nrChunk=$(expr "(" ${maxPos} "-" ${minPos} "+" 1 ")" "/" ${chunkSize} "+" 1)
    chrStartPos+=($(expr ${minPos} "-" 1))
    chunkCNT+=(${nrChunk})
    chunkCNTAll=$(expr ${chunkCNTAll} + ${nrChunk})
done

# scheme chunk splitting
chunkPerTasks=$(expr ${chunkCNTAll} / ${IMPUTE2threads}) # floor
chunkPerTasksRm=$(expr ${chunkCNTAll} % ${IMPUTE2threads}) # remained
chunkCum=0
chunkId=0
for chr in {1..22}; do
    for chunk in $( seq 1 ${chunkCNT[${chr}]} ); do
        # start a new chunk
        if [ ${chunkCum} -eq 0 ]; then
            startChr=${chr}
            startChunk=${chunk}
        fi
        # cumulation number of current chunk
        chunkCum=$(expr ${chunkCum} + 1)
        # end current chunk
        if [ ${chunkCum} -eq ${chunkPerTasks} ]; then
            chunkId=$(expr ${chunkId} + 1)
            endChr=${chr}
            endChunk=${chunk}
            srun \
                -p v6_384 -n 1 -c 1 --mem-per-cpu=15gb -t 48:00:00 -J s4_${chunkId} \
                bash $basepath/callImpute.sh \
                $workDir $softwareDir $referenceDir $fileName \
                $startChr $startChunk $endChr $endChunk &
            # update cumulation number of current chunk
            chunkCum=0
            # update cumulation threshold
            if [ ${chunkId} -eq $(expr ${IMPUTE2threads} - ${chunkPerTasksRm}) ]; then
                chunkPerTasks=$(expr ${chunkPerTasks} + 1)
            fi
        fi
    done
done
wait