#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --error=myJob.err
#SBATCH --output=myJob.out
#SBATCH --gres=gpu:1
#SBATCH --partition=g100_usr_interactive
#SBATCH --account=uBS21_InfGer_0
#SBATCH --time=00:30:00
#SBATCH --mem=32G


#### REF 05-06T14:43:31.653

export repertoire="05-06T11:21:55.052"
pwdd=$(pwd)
export path_to_repertoire=samples/puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2/logs/$repertoire
export domain=samples/puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2/logs/$repertoire/domain.pddl
export domain_nopre=samples/puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2/logs/$repertoire/domain-nopre.pddl
export problem_dir=problem-generators/backup-propositional/vanilla/puzzle-mnist-3-3/007-000
export problem_file="ama3_samples_puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2_logs_${repertoire}_domain_blind_problem.pddl"
#problem_nopre_file = "ama3_samples_puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2_logs_${repertoire}_domain-nopre_blind_problem.pddl"

export best_state_var=999

echo "in Meta 0"

######################
##     Functions    ##
######################

generate_invariants () {

    ### generate the actions
    ./train_kltune.py dump puzzle mnist 3 3 5000 CubeSpaceAE_AMA4Conv kltune2 $repertoire

    # ### generate PDDL domain
    ./pddl-ama3.sh $path_to_repertoire

    # ### generate PDDL problem (with preconditions)
    # ./ama3-planner.py $domain $problem_dir blind

    # ### reformat PDDLs
    # sed -i 's/+/plus/' $domain
    # sed -i 's/-/moins/' $domain
    # sed -i 's/negativemoinspreconditions/negative-preconditions/' $domain

    # cd ./downward

    # ### remove duplicates between preconditions and effects (in domain file)
    # python main.py 'remove_duplicates' ../$domain ../$problem_dir/$problem_file
    # ### remove NOT preconditions from the initial state (in problem file)
    # python main.py 'remove_not_from_prob' ../$domain ../$problem_dir/$problem_file

    # cd $pwdd/downward/src/translate/

    # ### Generate SAS file
    # python translate.py $pwdd/$domain $pwdd/$problem_dir/$problem_file

    # cd $pwdd/../h2-preprocessor/builds/release32/bin

    # ### Generate a new SAS file FROM h2 preprocessor
    # ./preprocess < $pwdd/downward/src/translate/output.sas --no_bw_h2

    # ### Generate a files of mutex
    # python ./retrieve_mutex.py

    # ### Copy the mutex file to the root dir
    # cp extracted_mutexes.txt $pwdd/

}


extract_current_invariant() {
    $(sed '2q;d' $pwdd/extracted_mutexes.txt) > current_invariant.txt
    $(sed '3q;d' $pwdd/extracted_mutexes.txt) >> current_invariant.txt
}

remove_current_invariant() {
    sed -i '1d' $pwdd/total_invariants.txt
    sed -i '2d' $pwdd/total_invariants.txt
    sed -i '3d' $pwdd/total_invariants.txt
    grep "\S" $pwdd/total_invariants.txt
}

return_state_var() {
    ## store it in # $pwdd/$path_to_repertoire/$repertoire/variance.txt
    ./train_kltune.py report puzzle mnist 3 3 5000 CubeSpaceAE_AMA4Conv kltune2 $repertoire
    local state_var=$(cat $pwdd/$path_to_repertoire/$repertoire/variance.txt)
    echo "$state_var"
}
echo "in Meta 1"

######################
## Initial training ##
######################
./train_kltune.py learn puzzle mnist 3 3 5000 CubeSpaceAE_AMA4Conv kltune2 $repertoire


#########################################
## Generate the invariants              #
#########################################
generate_invariants
