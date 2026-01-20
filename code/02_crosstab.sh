#!/bin/bash
#SBATCH --job-name=B5207_crstb                        # Job name
#SBATCH --mail-type=END,FAIL                        # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=pn22681@bristol.ac.uk           # Where to send mail
#SBATCH --ntasks=1                                  # Run on a single CPU
#SBATCH --mem=1gb                                  # Job memory request
#SBATCH --time=00:05:00                             # Time limit hrs:min:sec
#SBATCH --account=sscm028544                        # account used for the job

# initate mamba environment..
. ~/initMamba.sh
mamba activate standard

python 02_crosstab.py -i ../data/output/outputimp.tsv  -hp ../data/intermediate/Santi-HP-cnv-data.csv > 02.log

echo 'finished!'