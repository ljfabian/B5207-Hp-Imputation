#!/bin/bash
#SBATCH --job-name=B5207-Hp-imp                     # Job name
#SBATCH --mail-type=END,FAIL                        # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=pn22681@bristol.ac.uk           # Where to send mail
#SBATCH --ntasks=1                                  # Run on a single CPU
#SBATCH --mem=10gb                                  # Job memory request
#SBATCH --time=02:00:00                             # Time limit hrs:min:sec
#SBATCH --account=sscm028544                        # account used for the job

##########
# Error message
# Set up and delete temporary directory
##########

set -e
# if [ -z "$1" ] ; then 
#   echo "Usage: ./imputation_script.sh INPUT"
#   echo "no input file"
#   exit 1
# fi

if [ -z "$1" ]; then

    input=../data/input/data
else
    input=$1
fi

TEMP_DIR="$(mktemp -d -p .)"
trap "rm -rf $TEMP_DIR" EXIT
  
#############################
# to run script type command "./imputation_script.sh file" into terminal where file is the name of the input files before (not including) .bim/.bed/.fam
#############################

###########
#load modules
###########
module load languages/java-sdk
java -Xmx8g -jar ../data/beagle/beagle.25Nov19.28d.jar

###########
# Run imputation check program again to get real A1 alleles
##########
module load apps/plink1.9
plink --bfile $input --chr 16 --from-bp 71070878  --to-bp 73097663 --make-bed --out $TEMP_DIR/inputQC
plink --bfile $TEMP_DIR/inputQC --geno 0.1 --maf 0.05 --hwe 0.0000000001 --make-bed --out $TEMP_DIR/inputQC
plink --bfile $TEMP_DIR/inputQC --freq --out $TEMP_DIR/inputQCf

perl software/HRC-1000G-check-bim.pl -b $TEMP_DIR/inputQC.bim -f $TEMP_DIR/inputQCf.frq -r software/HRC.r1-1.GRCh37.wgs.mac5.sites.tab -h 

###########
# Convert plink bed/bim/fam to vcf
###########

plink --bfile $TEMP_DIR/inputQC --a2-allele Force-Allele1-inputQC-HRC.txt --recode vcf --out $TEMP_DIR/inputQCv

###########
# Haptoglobin imputation 
###########
module load bcftools

bcftools query -l $TEMP_DIR/inputQCv.vcf | sort | uniq -d

bcftools query -f "%CHROM\t%POS\n" ../data/intermediate/HP_Euroref_1kgOMNI_HM3_merged.GRCh37.vcf | awk '{print $1"\t.\t"$2/1e7"\t"$2}' > ../data/intermediate/mapfile

mapfile=../data/intermediate/mapfile

java -Xmx8g -jar ../data/beagle/beagle.25Nov19.28d.jar gt=$TEMP_DIR/inputQCv.vcf ref=../data/intermediate/HP_Euroref_1kgOMNI_HM3_merged.GRCh37.vcf out=../data/output/output_imp map=$mapfile

###########
# Extract HP alleles
###########
bcftools index -ft "../data/output/output_imp.vcf.gz" && bcftools query -f "[%SAMPLE\t%ALT\t%GT\n]" "../data/output/output_imp.vcf.gz" -r 16:72092044-72092044 | tr -d '[<>]' | awk -F"\t" -v OFS="\t" '{split($2,a,","); a["0"]="NA"; split($3,b,"|"); print $1,a[b[1]],a[b[2]]}' > ../data/output/outputimp.tsv

rm *.txt