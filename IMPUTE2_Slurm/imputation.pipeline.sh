# get absolute path of current bash script
basepath="$1"

# source sub script
source $basepath/read_ini.sh

# input configure paraments
workDir=$(read_ini $basepath/para.ini imputation workDir)
dataDir=$(read_ini $basepath/para.ini imputation dataDir)
softwareDir=$(read_ini $basepath/para.ini imputation softwareDir)
liftOverReferDir=$(read_ini $basepath/para.ini imputation liftOverReferDir)
referenceDir=$(read_ini $basepath/para.ini imputation referenceDir)
referenceDirX=$(read_ini $basepath/para.ini imputation referenceDirX)
sourceBuild=$(read_ini $basepath/para.ini imputation sourceBuild)
fileName=$(read_ini $basepath/para.ini imputation fileName)
SHAPEITthreads=$(read_ini $basepath/para.ini imputation SHAPEITthreads)
IMPUTE2threads=$(read_ini $basepath/para.ini imputation IMPUTE2threads)

preIndMissThreshold=$(read_ini $basepath/para.ini preQC indMissThreshold)
preSnpMissThreshold=$(read_ini $basepath/para.ini preQC snpMissThreshold)
preMafThreshold=$(read_ini $basepath/para.ini preQC mafThreshold)
preHweThreshold=$(read_ini $basepath/para.ini preQC hweThreshold)

afterMissThreshold=$(read_ini $basepath/para.ini afterQC missThreshold)
afterMafThreshold=$(read_ini $basepath/para.ini afterQC mafThreshold)
afterHweThreshold=$(read_ini $basepath/para.ini afterQC hweThreshold)
afterInfoThreshold=$(read_ini $basepath/para.ini afterQC infoThreshold)

# step1 QC / liftOver to hg19 / remove duplicate snps
jid1=$(sbatch \
            -p v6_384 -n 1 -c 1 --mem=1gb -t 10 -J s1 --parsable \
            $basepath/step1.sh \
            $workDir $dataDir $softwareDir $liftOverReferDir $sourceBuild $fileName \
            $preIndMissThreshold $preSnpMissThreshold $preMafThreshold $preHweThreshold)

# # step2 extract unique snps between reference and raw
jid2=$(sbatch \
            --dependency=afterok:${jid1} \
            -p v6_384 -n 1 -c 8 --mem=20gb -t 10 -J s2  --parsable \
            $basepath/step2.sh \
            $workDir $softwareDir $referenceDir $fileName)

# step3 SHAPEIT
jid3=$(sbatch \
            --dependency=afterok:${jid2} \
            -p v6_384 -n 22 -c $SHAPEITthreads --mem=80gb -t 10:00:00 -J s3 --parsable\
            $basepath/step3.sh \
            $workDir $softwareDir $referenceDir $fileName $SHAPEITthreads)

# step4 IMPUTE2
jid4=$(sbatch \
            --dependency=afterok:${jid3} \
            -p v6_384 -n $IMPUTE2threads -c 1 --mem-per-cpu=15gb -t 48:00:00 -J s4 --parsable \
            $basepath/step4.sh \
            $workDir $softwareDir $referenceDir $fileName $IMPUTE2threads $basepath)

# step5 merge results
jid5=$(sbatch \
            --dependency=afterok:${jid4} \
            -p v6_384 -n 22 -c 1 --mem-per-cpu=10gb -t 20 -J s5  --parsable \
            $basepath/step5.sh \
            $workDir $softwareDir $fileName)

# step6 QC
jid6=$(sbatch \
            --dependency=afterok:${jid5} \
            -p v6_384 -n 1 -c 4 --mem=10gb -t 20 -J s6  --parsable \
            $basepath/step6.sh \
            $workDir $softwareDir $fileName $basepath \
            $afterMissThreshold $afterMafThreshold $afterHweThreshold $afterInfoThreshold)

# step7 reattach origin data
jid7=$(sbatch \
            --dependency=afterok:${jid6} \
            -p v6_384 -n 1 -c 4 --mem=10gb -t 20 -J s7  --parsable \
            $basepath/step7.sh \
            $workDir $dataDir $softwareDir $fileName $basepath)

# accounting data for all steps
sbatch \
    --dependency=afterany:${jid1}:${jid2}:${jid3}:${jid4}:${jid5}:${jid6}:${jid7} \
    $basepath/jobsAccounting.sh \
    ${jid1} ${jid2} ${jid3} ${jid4} ${jid5} ${jid6} ${jid7}
    
    