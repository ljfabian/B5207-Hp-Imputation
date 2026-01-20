#!/bin/bash
#SBATCH --job-name=B5207-prep-files                 # Job name
#SBATCH --mail-type=END,FAIL                        # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=pn22681@bristol.ac.uk           # Where to send mail
#SBATCH --ntasks=1                                  # Run on a single CPU
#SBATCH --mem=10gb                                  # Job memory request
#SBATCH --time=02:00:00                             # Time limit hrs:min:sec
#SBATCH --account=sscm028544                        # account used for the job

# Code performs liftover. This is required if the data is on hg36 only, i.e. gwa_550_g1. 

set -e
if [ -z "$1" ] ; then 
  echo "no input array file specified"
  exit 1
fi

# load modules
module load apps/plink1.9

# make a temp dir
TEMP_DIR="$(mktemp -d -p .)"
trap "rm -rf $TEMP_DIR" EXIT

cp $1.* $TEMP_DIR/

## prep for Liftover from 36 to 37
awk -F '\t' '{print "chr"$1"\t"($4-1)"\t"$4"\t"$2}' \
    $TEMP_DIR/data.bim \
    > $TEMP_DIR/data.ucsc.bed

# perform liftover
~/liftover/liftOver $TEMP_DIR/data.ucsc.bed \
    ~/liftover/hg18ToHg19.over.chain.gz \
    $TEMP_DIR/data_lifted.ucsc.bed $TEMP_DIR/data_unlifted.bed


# count snps before and after liftover
echo 'before and after lifting counts:'
wc -l $TEMP_DIR/data.ucsc.bed
wc -l $TEMP_DIR/data_lifted.ucsc.bed

# remove in place all comments
sed -i '/^#/d' $TEMP_DIR/data_unlifted.bed

# check unlifted snps
echo 'Unlifted:'
wc -l $TEMP_DIR/data_unlifted.bed

# create map for plink files
awk 'BEGIN{OFS="\t"} {gsub(/^chr/,"",$1); print $4, $1, $3}' \
    $TEMP_DIR/data_lifted.ucsc.bed \
    > $TEMP_DIR/lifted.map

# select unlifted snps
awk '{print $4}' $TEMP_DIR/data_unlifted.bed > $TEMP_DIR/unlifted.snps

# update plink files, dropping unlifted
plink \
    --bfile $TEMP_DIR/data \
    --exclude $TEMP_DIR/unlifted.snps \
    --update-map $TEMP_DIR/lifted.map 3 1 \
    --make-bed \
    --out ../data/input/data

# check for duplicate snps
plink --bfile ../data/input/data --list-duplicate-vars suppress-first

echo 'finished!'