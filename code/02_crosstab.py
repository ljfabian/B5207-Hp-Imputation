import pandas as pd
import argparse
import B5207filepaths as fp

def init():
    parser = argparse.ArgumentParser(description='general command line options. -h for info.')
    parser.add_argument('-i', '--imp', action='store', required=False, help='Location of imputed file')
    parser.add_argument('-hp', '--hp', action='store', required=True, help='Location of Santis CNV data file')
    return parser.parse_args()

def main():
    
    opts = init()
    
    # all wocs together
    with open(fp.allwoc_filepath, 'r') as f:
        wocs = [i.strip() for i in f]
        
    # just wocs
    with open(fp.woc_filepath, 'r') as f:
        wocs = [i.strip() for i in f]

    # just trips/quads
    with open(fp.tq_filepath, 'r') as f:
        tqs = [i.strip() for i in f]
        
    # just non-enrolled
    with open(fp.non_enrolled, 'r') as f:
        non_enrolled = [i.split(' ')[0] for i in f]
         
    # relatedness matrices loaded
    with open(fp.relatedness_exclusion_filepath, 'r') as f:
        rltds = [i.split(' ')[0] for i in f]
    
    with open(fp.relatedness_inclusion_filepath, 'r') as f:
        incld_rltds = [i.split('\t')[0] for i in f]  
    
    # load the files
    hp_assay = pd.read_csv(opts.hp, dtype=str, header=0)
    print(hp_assay)
    
    print('number of indviduals in assay who aren\'t enrolled:', len([i for i in hp_assay['alnqlet'] if i in non_enrolled]))
    
    # load imputed HP genotypes, plus the fix for alnqlet
    hp_imp = pd.read_csv(opts.imp, dtype=str, sep='\t', names=['aln_qlet', 'hp1', 'hp2'])
    hp_imp['alnqlet'] = [str(i).split('_')[0] for i in hp_imp['aln_qlet']]

    print(hp_imp)
    
    # Fix the imputed marker so it matches array
    hp_imp['hp_imp'] = [r['hp1'][2] + '_' + r['hp2'][2] for i, r in hp_imp.iterrows()]
    hp_imp['hp_imp'] = ['1_2' if i == '2_1' else i for i in hp_imp['hp_imp'] ] # convert so 1_2 and 2_1 are matched as the same
    
    # merge
    df = pd.merge(hp_assay, hp_imp, how='left', on='alnqlet')

    print('Number of B qlets present:', len([i for i in list(df['alnqlet']) if 'B' in i]))

    # lots of crosstabbing, but checking each woc scenario
    for crstb_removals in [[wocs + tqs, 'WoCs, tripquads'], 
                           [wocs + tqs + rltds, 'WoCs, tripquads & relateds']]:
                
        # removals
        print('testing removals:', crstb_removals[1])
        x = df[~df['alnqlet'].isin(crstb_removals[0])]
        
        # crosstab it
        crstb = pd.crosstab(x['hp'], x['hp_imp'])
        print(crstb)
        
        x = df[df['alnqlet'].isin(incld_rltds)]
        
        # crosstab it
        crstb = pd.crosstab(x['hp'], x['hp_imp'])
        print('filtering to inclusion list for relateds:\n', crstb)
   
    

if __name__=='__main__':
    main()
