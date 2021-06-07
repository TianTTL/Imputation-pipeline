#!/bin/bash

workDir="$1"
dataDir="$2"
softwareDir="$3"
fileName="$4"
basepath="$5"

if [ ! -s ${workDir}/step7 ]; then
  mkdir ${workDir}/step7
fi

# filter low quality SNPs from original data
${softwareDir}/R --slave <${basepath}/filterOrigin.R --args \
        "${dataDir}/${fileName}.bim" \
        "${workDir}/step6/${fileName}.imputed.bim" \
        "${workDir}/step7/origin.within.list"

# extract low quality SNPs from original data
if [ -f ${dataDir}/${fileName}.bed ]; then
    ${softwareDir}/plink \
        --bfile ${dataDir}/${fileName}\
        --extract ${workDir}/step7/origin.within.list\
        --make-bed\
        --out ${workDir}/step7/${fileName}.origin.within\
        --allow-no-sex
elif [ -f ${dataDir}/${fileName}.ped ]; then
    ${softwareDir}/plink \
        --file ${dataDir}/${fileName}\
        --extract ${workDir}/step7/origin.within.list\
        --make-bed\
        --out ${workDir}/step7/${fileName}.origin.within\
        --allow-no-sex
elif [ -f ${dataDir}/${fileName}.tped ]; then
    ${softwareDir}/plink \
        --tfile ${dataDir}/${fileName}\
        --extract ${workDir}/step7/origin.within.list\
        --make-bed\
        --out ${workDir}/step7/${fileName}.origin.within\
        --allow-no-sex
fi

# merge
${softwareDir}/plink \
  --bfile ${workDir}/step6/${fileName}.imputed\
  --bmerge ${workDir}/step7/${fileName}.origin.within\
  --make-bed\
  --merge-mode 2\
  --out ${workDir}/step7/${fileName}.imputed.reattach \
  --allow-no-sex \
  --allow-no-vars

# check the freq of result
# ${softwareDir}/plink \
#   --bfile ${workDir}/step7/${fileName}.imputed.reattach\
#   --freq\
#   --out ${workDir}/step7/${fileName}.imputed.reattach\
#   --allow-no-sex

