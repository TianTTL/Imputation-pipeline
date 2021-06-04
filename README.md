# Imputation-pipeline

## 设计

适用于搭载了SLURM系统的Linux集群服务器，使用千人基因组作为reference panel，以IMPUTE2 best practice 为参考，构建 genotype imputation 流程

## 依赖

本流程依赖 `liftOver` `plink` `SHAPEIT` `IMPUTE2` ，以及相应的reference 数据

## 使用说明

1. 输入数据应为 `bed/bim/fam`格式，将它们移动到同一个路径下，记为 `$dataDir`

    尽可能保证输入数据的genome build是hg19

   尽可能不要使用易混淆单词作为文件名，如:“merge”,"result"

2. 将全部脚本拷贝到一个路径下，记为 `$basepath`

3. 准备一个路径用于存放工作过程数据，记为 `$workDir`

4. 设置参数文件`para.ini`

5. 运行命令

   `sbatch imputation.pipeline.sh $basepath`

## 参数设置

```ini
[imputation]
# 原始数据目录
dataDir = /public1/home/sc80541/gaoxj/imputation/STS20210506/data
# 原始数据文件名
fileName = merged
# 原始数据genome build
sourceBuild = hg19
# 工作目录
workDir = /public1/home/sc80541/gaoxj/imputation/pipeline.optimize
# 软件可执行文件目录
softwareDir = /public1/home/sc80541/public_software/bin
# liftOver chainfile 位置
liftOverReferDir = /public1/home/sc80541/gaoxj/imputation/referenceData/liftOver_chainFile
# 千人基因组常染色体haplotype文件目录
referenceDir = /public1/home/sc80541/gaoxj/imputation/referenceData/1000G.Haplotype
# 千人基因组X染色体haplotype文件目录
referenceDirX = /public1/home/sc80541/gaoxj/imputation/referenceData/1000G.Haplotype
# SHAPEIT运行并行数，不应超过4
SHAPEITthreads = 4
# IMPUTE2运行并行数，不应超过99
IMPUTE2threads = 90

# imputation前质控标准，各项等同plink
[preQC]
indMissThreshold = 1
snpMissThreshold = 0.05
mafThreshold = 0.001
hweThreshold = 1e-4

# imputation前质控标准，各项等同plink
[afterQC]
missThreshold = 0.05
mafThreshold = 0.01
hweThreshold = 1e-4
# imputation位点质量质控标准，不应小于0.4
infoThreshold = 0.6

```

## 运行测试

•743722 SNPs

•1932 samples

| 步骤 | 运行时间 | 最大并行数 | 最大占用内存 |
| ---- | -------- | ---------- | ------------ |
| S1   | 00:02:53 | 1          | 3GB          |
| S2   | 00:05:22 | 8          | 10GB         |
| S3   | 02:14:36 | 88         | 18GB         |
| S4   | 21:15:08 | 90         | 1.2TB        |
| S5   | 00:01:48 | 22         | 82GB         |
| S6   | 00:07:51 | 4          | 4.9GB        |
| s7   | 00:01:15 | 4          | 3.9GB        |

