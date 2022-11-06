#!/bin/bash

export repertoire="SomeTime50"
pwdd=$(pwd)
export path_to_repertoire=samples/puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2/logs/$repertoire
export domain=samples/puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2/logs/$repertoire/domain.pddl
export domain_nopre=samples/puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2/logs/$repertoire/domain-nopre.pddl
export problem_dir=problem-generators/backup-propositional/vanilla/puzzle-mnist-3-3/007-000
export problem_file="ama3_samples_puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2_logs_${repertoire}_domain_blind_problem.pddl"
#problem_nopre_file = "ama3_samples_puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2_logs_${repertoire}_domain-nopre_blind_problem.pddl"

export best_state_var=999

######################
##     Functions    ##
######################

generate_invariants () {

    ### generate the actions
    ./train_kltune.py dump puzzle mnist 3 3 5000 CubeSpaceAE_AMA4Conv kltune2 $repertoire

    ### generate PDDL domain
    ./pddl-ama3.sh $path_to_repertoire

    ### generate PDDL problem (with preconditions)
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

    ### Generate SAS file
    python translate.py $pwdd/$domain $pwdd/$problem_dir/$problem_file

    cd $pwdd/../h2-preprocessor/builds/release32/bin

    ### Generate a new SAS file FROM h2 preprocessor
    ./preprocess < $pwdd/downward/src/translate/output.sas --no_bw_h2

    ### Generate a files of mutex
    python ./retrieve_mutex.py

    ### Copy the mutex file to the root dir
    cp extracted_mutexes.txt $pwdd/

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


######################
## Initial training ##
######################
./train_kltune.py learn puzzle mnist 3 3 5000 CubeSpaceAE_AMA4Conv kltune2 $repertoire

#########################################
## Generate the invariants              #
#########################################
generate_invariants

##################################################################
## Compute State Variance  and store it in state_var             #
##################################################################
best_state_var="$(return_state_var)"


export nb_inv_left=$(grep -o '#' extracted_mutexes.txt | wc -l)

# copy the found mutexes to total_invariants
cp extracted_mutexes.txt total_invariants.txt

# while there still invariants in total_invariants.txt
while [ ! -s total_invariants.txt ]
do
    # Update current_invariant.txt
    extract_current_invariant

    # Remove from total_invariants.txt
    remove_current_invariant

    # Each training is COMPLETLY NEW (even the loss function)
    ./train_kltune.py learn puzzle mnist 3 3 5000 CubeSpaceAE_AMA4Conv kltune2 $repertoire

    # Once trained, update the State Variance (state_var)
    local current_state_var="$(return_state_var)"

    # If state variance < best_so_far
    if [ current_state_var -lt best_state_var ];
    then
        # we add the invariant to omega.txt
        cat current_invariant.txt >> omega.txt

        # Generate new invariants
        generate_invariants

        # Add the extracted invariants to the total list
        cat extracted_mutexes.txt >> total_invariants.txt

        # Remove duplicates
        remove_duplicate_invariants.py total_invariants.txt

        # update best score
        best_state_var=current_state_var
    fi
done