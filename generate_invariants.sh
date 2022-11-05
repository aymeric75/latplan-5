#!/bin/bash


# Variables

pwdd=$(pwd)

export repertoire="05-06T16:13:22.480"

export path_to_repertoire=samples/puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2/logs/$repertoire

export domain=samples/puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2/logs/$repertoire/domain.pddl
export domain_nopre=samples/puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2/logs/$repertoire/domain-nopre.pddl
export problem_dir=problem-generators/backup-propositional/vanilla/puzzle-mnist-3-3/007-000

export problem_file="ama3_samples_puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2_logs_${repertoire}_domain_blind_problem.pddl"
#problem_nopre_file = "ama3_samples_puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2_logs_${repertoire}_domain-nopre_blind_problem.pddl"

# # generate the actions
# ./train_kltune.py dump puzzle mnist 3 3 5000 CubeSpaceAE_AMA4Conv kltune2 $repertoire


# # # generate PDDL domain
# ./pddl-ama3.sh $path_to_repertoire


# # # generate PDDL problem
# # # With preconditions
# ./ama3-planner.py $domain $problem_dir blind
# # # # WithOUT preconditions
# ./ama3-planner.py $domain_nopre $problem_dir blind

# # REFORMAT PDDL files
# # Replace + and - by plus and moins (in domain file)

# sed -i 's/+/plus/' $domain
# sed -i 's/-/moins/' $domain
# sed -i 's/negativemoinspreconditions/negative-preconditions/' $domain

# sed -i 's/+/plus/' $domain_nopre
# sed -i 's/-/moins/' $domain_nopre
# sed -i 's/negativemoinspreconditions/negative-preconditions/' $domain_nopre

# # remove duplicates between preconditions and effects (in domain file)
# cd ./downward
# python main.py 'remove_duplicates' ../$domain ../$problem_dir/$problem_file

# # remove NOT preconditions from the initial state (in problem file)
# python main.py 'remove_not_from_prob' ../$domain ../$problem_dir/$problem_file


### Generate SAS file in latplan5.0.0/downward/src/translate (used after, for h2 preprocessor)
cd $pwdd/downward/src/translate/
python translate.py $pwdd/$domain $pwdd/$problem_dir/$problem_file

#### Generate a new SAS file FROM h2 preprocessor, with the 
cd $pwdd/../h2-preprocessor/builds/release32/bin
./preprocess < $pwdd/downward/src/translate/output.sas --no_bw_h2
# Check que c'est bien le output.sas de $(pwd)/downward/src/translate/ qui est régénéré
# DU COUP NON ..

#### (new SAS is in $pwdd/../h2-preprocessor/builds/release32/bin)
#### Generate a files of mutex and copy it where needed
python ./retrieve_mutex.py

cp extracted_mutexes.txt $pwdd/

# # # python ./downward/src/translate/translate.py $domain $problem_nopre_file