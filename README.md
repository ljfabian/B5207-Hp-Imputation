# 05/01/2026 - Haptoglobin imputation: A validation study

# Description
Ian Galea (Soton) got in touch with exec about summary statistics for an old paper/study that he was part of, which was ran when Nabila Kazmi was working in the IEU.

Nabila had imputed the HP genotype for 7978 ALSPAC children and 753 of these overlapped with Santi's ARCS-derived HP CNV data. The Hp imputation is using the method of Boettger et al: https://doi.org/10.1038/ng.3510. This should be done on the array dataset (gwa_550_g1).

## Files
- `beagle.25Nov19.28d.jar`: Downloaded archive beagle Jar file from University of Washington server (https://faculty.washington.edu/browning/beagle/beagle.25Nov19.28d.jar). 
- `software/`: Files relating to pre-imputation QC, downloaded following imputation server guidance: https://imputationserver.readthedocs.io/en/latest/prepare-your-data/#execute-script. 
- Needed to perform liftover from 36 to 37, done with chain file: `https://hgdownload.soe.ucsc.edu/goldenPath/hg18/liftOver/hg18ToHg19.over.chain.gz`

# Code
`code/SOTON-imputation_script.sh` was shared to us by Emma Dewhurst, at Soton. 
Adapted to run on BP by LF, runs with command:

## 3 versions tested:

Counts did not quite add up as expected, to reach 
- 927 cases with Santi’s CNV assay
- 7977 ALSPAC children
which was requested. I have been testing different versions, to see which would reach the closest counts of variants. 

### 550 array
steps:
1. `sbatch 00_prep_input.sh /group/alspacdata/datasets/dataset_gwa_550_g1/released/2022-12-05/data/data` - Performs liftover from hg36-> hg37, after current wocs being ran. 
2. `sbatch 01_imputation_script.sh` - performs imputation for HP alleles, following Soton shared code. 
3. `sbatch 02_crosstab.sh` - runs python code generating the crosstab.

### Combined dataset (ALSPAC_18K)

1. `sbatch 01_imputation_script.sh /group/alspacdata/datasets/dataset_gi_topmed_g0_g1/dev/data/geno/g0m_g1/ALSPAC_18K` - perform imputation for HP alleles following Soton shared code. 
2. `sbatch 02_crosstab.sh` - runs python code generating the crosstab.

### Combined dataset (ALSPAC_18K) with GOSH filtering

At Ians suggestion, we also tried with the same GOSH cohort filtering they previously used applied, which is `--mind 0.1 --geno 0.1 --maf 0.05 --hwe 0.0000000001`.

1. `sbatch 01_imputation_script-qc.sh /group/alspacdata/datasets/dataset_gi_topmed_g0_g1/dev/data/geno/g0m_g1/ALSPAC_18K` - perform imputation for HP alleles following Soton shared code. This adds in the `--mind 0.1` QC step. THis is the only difference. 
2. `sbatch 02_crosstab.sh` - runs python code generating the crosstab.

This has been the accepted closest version of the dataset. The PCR matches, just minus standard expected withdrawals over the time. There are differences in the imputation counts, but there is no large issue with this providing we have the code/QC applied to the other cohort. 
