#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
#SBATCH --partition=g100_usr_interactive
#SBATCH --account=uBS21_InfGer_0
#SBATCH --time=08:00:00
#SBATCH --mem=32G

## PUZZLE MNIST
#SBATCH --error=myJobMeta_mnistLOL.err
#SBATCH --output=myJobMeta_mnistLOL.out
task="puzzle"
type="mnist"
width_height="3 3"
nb_examples="5000"
label="mnist"
after_sample="puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2"
pb_subdir="puzzle-mnist-3-3"

rep_model="05-06T11:21:55.052"



domain=samples/$after_sample/logs/$rep_model/domain.pddl
path_to_repertoire=samples/$after_sample/logs/$rep_model
problem_file="ama3_samples_${after_sample}_logs_${rep_model}_domain_blind_problem.pddl"
problems_dir=problem-generators/backup-propositional/vanilla/$pb_subdir



current_problems_dir=$problems_dir/007-000


pwdd=$(pwd)


# generate extracted_mutexes_* and put it in root
generate_invariants () {

    ### generate the actions
    ./train_kltune.py dump $task $type $width_height $nb_examples CubeSpaceAE_AMA4Conv kltune2 $rep_model

    ### generate PDDL domain
    ./pddl-ama3.sh $path_to_repertoire

    ### generate PDDL problem (with preconditions)
    ./ama3-planner.py $domain $current_problems_dir blind

    ### reformat PDDLs
    sed -i 's/+/plus/' $domain
    sed -i 's/-/moins/' $domain
    sed -i 's/negativemoinspreconditions/negative-preconditions/' $domain

    cd ./downward

    ### remove duplicates between preconditions and effects (in domain file)
    python main.py 'remove_duplicates' ../$domain ../$current_problems_dir/$problem_file
    ### remove NOT preconditions from the initial state (in problem file)
    python main.py 'remove_not_from_prob' ../$domain ../$current_problems_dir/$problem_file

    cd $pwdd/downward/src/translate/

    ### Generate SAS file
    python translate.py $pwdd/$domain $pwdd/$current_problems_dir/$problem_file --sas-file output_$label.sas
    
    cd $pwdd/../h2-preprocessor/builds/release32/bin

    ### Generate a new SAS file FROM h2 preprocessor
    ./preprocess < $pwdd/downward/src/translate/output_$label.sas --no_bw_h2

    mv output.sas output_$label.sas

    ### Generate a files of mutex
    python ./retrieve_mutex.py output_$label.sas $label

    ### Copy the mutex file to the root dir
    cp extracted_mutexes_$label.txt $pwdd/
    cd $pwdd/
}




# # train
# ./train_kltune.py learn $task $type $width_height $nb_examples CubeSpaceAE_AMA4Conv kltune2 $rep_model
# #./train_kltune.py reproduce $task $type $width_height $nb_examples CubeSpaceAE_AMA4Conv kltune2 $rep_model

### generate the actions
./train_kltune.py dump $task $type $width_height $nb_examples CubeSpaceAE_AMA4Conv kltune2 $rep_model

### generate PDDL domain
./pddl-ama3.sh $path_to_repertoire

### generate PDDL problem (with preconditions)
./ama3-planner.py $domain $current_problems_dir blind


### reformat PDDLs
sed -i 's/+/plus/' $domain
sed -i 's/-/moins/' $domain
sed -i 's/negativemoinspreconditions/negative-preconditions/' $domain

cd ./downward

### remove duplicates between preconditions and effects (in domain file)
python main.py 'remove_duplicates' ../$domain ../$current_problems_dir/$problem_file
### remove NOT preconditions from the initial state (in problem file)
python main.py 'remove_not_from_prob' ../$domain ../$current_problems_dir/$problem_file

cd $pwdd/downward/src/translate/

### Generate SAS file
python translate.py $pwdd/$domain $pwdd/$current_problems_dir/$problem_file --sas-file output_$label.sas

cd $pwdd/../h2-preprocessor/builds/release32/bin

### Generate a new SAS file FROM h2 preprocessor
./preprocess < $pwdd/downward/src/translate/output_$label.sas --no_bw_h2

mv output.sas output_$label.sas

### Generate a files of mutex
python ./retrieve_mutex.py output_$label.sas $label

### Copy the mutex file to the root dir
cp extracted_mutexes_$label.txt $pwdd/