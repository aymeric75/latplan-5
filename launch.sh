#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --error=myJob480Bis.err
#SBATCH --output=myJob480Bis.out
#SBATCH --gres=gpu:1
#SBATCH --partition=g100_usr_interactive
#SBATCH --account=uBS21_InfGer_0
#SBATCH --time=00:30:00
#SBATCH --mem=32G

export label="blocks422"

export repertoire="05-15T23:44:49.422"
pwdd=$(pwd)
export path_to_repertoire=samples/blocks_cylinders-4-flat_20000_CubeSpaceAE_AMA4Conv_kltune2/logs/$repertoire
export domain=samples/blocks_cylinders-4-flat_20000_CubeSpaceAE_AMA4Conv_kltune2/logs/$repertoire/domain.pddl
export domain_nopre=samples/blocks_cylinders-4-flat_20000_CubeSpaceAE_AMA4Conv_kltune2/logs/$repertoire/domain-nopre.pddl
export problem_dir=problem-generators/backup-propositional/vanilla/prob-cylinders-4/007-001
export problem_file="ama3_samples_blocks_cylinders-4-flat_20000_CubeSpaceAE_AMA4Conv_kltune2_logs_${repertoire}_domain_blind_problem.pddl"
export best_state_var=999





#./train_kltune.py resume puzzle mnist 3 3 5000 CubeSpaceAE_AMA4Conv kltune2 "05-06T16:13:22.480"

#./train_kltune.py reproduce puzzle mnist 3 3 5000 CubeSpaceAE_AMA4Conv kltune2

#./train_kltune.py dump puzzle mnist 3 3 5000 CubeSpaceAE_AMA4Conv kltune2 "SomeTime47"

# ./train_kltune.py report puzzle mnist 3 3 5000 CubeSpaceAE_AMA4Conv kltune2 "05-06T11:21:55.052"

###################
## TRAIN the stuff from begining with MetaLearning
################### 
# > to load from a JSON file, put it in the hash path
# > to specify specific parameters (size of N ?): put it before in the code



# # training
# ./train_kltune.py learn puzzle mnist 3 3 5000 CubeSpaceAE_AMA4Conv kltune2 "SomeTime480Bis"

# is it not smarter to test all the invariants at once ? will take less time, we have more chance to see a real effect

# to Masataro : we want to see the effect of the invariants on the state invariance

#   is this the state invariance ?

# ### generate the actions
# ./train_kltune.py dump puzzle mnist 3 3 5000 CubeSpaceAE_AMA4Conv kltune2 $repertoire

# ### generate PDDL domain
./pddl-ama3.sh $path_to_repertoire


# ### generate PDDL problem (with preconditions)
./ama3-planner.py $domain $problem_dir blind

### reformat PDDLs
sed -i 's/+/plus/' $domain
sed -i 's/-/moins/' $domain
sed -i 's/negativemoinspreconditions/negative-preconditions/' $domain

cd ./downward

### remove duplicates between preconditions and effects (in domain file)
python main.py 'remove_duplicates' ../$domain ../$problem_dir/$problem_file
### remove NOT preconditions from the initial state (in problem file)
python main.py 'remove_not_from_prob' ../$domain ../$problem_dir/$problem_file

cd $pwdd/downward/src/translate/

python translate.py $pwdd/$domain $pwdd/$problem_dir/$problem_file --sas-file output_$label.sas

cd $pwdd/../h2-preprocessor/builds/release32/bin

### Generate a new SAS file FROM h2 preprocessor
./preprocess < $pwdd/downward/src/translate/output_$label.sas --no_bw_h2

mv output.sas output_$label.sas

# ### Generate a files of mutex
python ./retrieve_mutex.py output_$label.sas $label