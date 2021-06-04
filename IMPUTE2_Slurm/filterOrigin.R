library(data.table)
Args <- commandArgs(TRUE)

origin.bim <- fread(Args[1])
impute.bim <- fread(Args[2])
origin.bim$V3 <- origin.bim$V1 * 1000000000 + origin.bim$V4
impute.bim$V3 <- impute.bim$V1 * 1000000000 + impute.bim$V4
origin.bim.without <- origin.bim[!origin.bim$V3 %in% impute.bim$V3]
write.table(origin.bim.without$V2, Args[3], quote=F, row.names=F, col.names=F)
