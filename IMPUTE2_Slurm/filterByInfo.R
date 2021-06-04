library(data.table)
Args <- commandArgs(TRUE)

infoThreshold <- as.numeric(Args[1])

infoScore <- fread(Args[2])
write.table(infoScore[info > infoThreshold, rs_id], Args[3], row.names=FALSE,col.names=FALSE,quote = FALSE)