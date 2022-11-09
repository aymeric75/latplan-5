#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --error=myJobMeta.err
#SBATCH --output=myJobMeta.out
#SBATCH --gres=gpu:1
#SBATCH --partition=g100_usr_interactive
#SBATCH --account=uBS21_InfGer_0
#SBATCH --time=08:00:00
#SBATCH --mem=32G


#
# Files:
#  extracted_mutexes_$label.txt (in h2 and in root)
#  total_invariants_$label.txt (in root)
#  variance.txt (in logs)
#  omega_$label.txt (in root)

#### REF 05-06T16:13:22.480

export label="puzzle480"

export repertoire="SomeTime480"
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
    python translate.py $pwdd/$domain $pwdd/$problem_dir/$problem_file --sas-file output_$label.sas
    
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


extract_current_invariant() {
    sed -n '2p' extracted_mutexes_$label.txt > current_invariant.txt
    sed -n '3p' extracted_mutexes_$label.txt >> current_invariant.txt
}

remove_current_invariant() {
    sed -i '1,3d' $pwdd/total_invariants_$label.txt
}

current_state_var=999



#################### !!!!!!!!!!!!!!!!!!!
#########################################################################################
## Generate the invariants    (domain.pddl problem.pddl extracted_mutexes_$label.txt)              OK   #
#########################################################################################
generate_invariants
echo "in Meta 2"

# ##################################################################
# ## Compute State Variance  and store it in state_var             #
# ##################################################################
#cd $pwdd
./train_kltune.py report puzzle mnist 3 3 5000 CubeSpaceAE_AMA4Conv kltune2 $repertoire
current_state_var=$(cat $pwdd/$path_to_repertoire/variance.txt)
best_state_var=$current_state_var

echo "in Meta 3"

echo $best_state_var

echo "in Meta 4"

# when variance is 0.0 smth's wrong, we set it high instead
comparison=$(./a_inf_b.py $best_state_var 0.0) # a <= b ? 1 : 0
if [ $comparison -eq 1 ]
then
    best_state_var=99
fi

echo "in Meta 5"
echo $best_state_var

echo "Base state_var" > omega_$label.txt
echo $best_state_var >> omega_$label.txt

# copy the found mutexes to total_invariants_$label                        OK
cp $pwdd/extracted_mutexes_$label.txt $pwdd/total_invariants_$label.txt

echo "in Meta 6"

nb_invariants=$(./count_invariants.py $pwdd/total_invariants_$label.txt)

echo $nb_invariants

# while there still invariants in total_invariants_$label.txt
while [ $nb_invariants -gt 0 ]
do
    echo "IN WHILEE"
    # Update current_invariant.txt (there are only 2 lines in this file)
    extract_current_invariant

    # Remove from total_invariants_$label.txt
    remove_current_invariant

    # Each training is COMPLETLY NEW (even the loss function)
    ./train_kltune.py learn puzzle mnist 3 3 5000 CubeSpaceAE_AMA4Conv kltune2 $repertoire

    ## Once trained, update the State Variance (state_var)
    cd $pwdd
    ./train_kltune.py report puzzle mnist 3 3 5000 CubeSpaceAE_AMA4Conv kltune2 $repertoire
    current_state_var=$(cat $pwdd/$path_to_repertoire/variance.txt)

    echo "current_state_var (after training)"
    echo $current_state_var

    comparison=$(./a_inf_b.py $current_state_var 0.0) # If retrieved state_var is 0.0 we update to 99
    if [ $comparison -eq 1 ]                          # so we can test it against best_state_var
    then
        current_state_var=99
    fi

    # # If state variance <= best_so_far (we add the invariant to omega_$label, along with the corres)
    comparison=$(./a_inf_b.py $current_state_var $best_state_var) # nb1 <= nb2

    if [ $comparison -eq 1 ]
    then
        # we add the invariant to omega_$label.txt
        echo "#" >> omega_$label.txt
        cat current_invariant.txt >> omega_$label.txt
        echo $current_state_var >> omega_$label.txt

        # We update the total_invariants_$label list

        # Generate new invariants
        generate_invariants

        # Add the extracted invariants to the total list
        cat extracted_mutexes_$label.txt >> total_invariants_$label.txt

        # Remove duplicates
        ./remove_duplicate_invariants.py total_invariants_$label.txt

        # update best score
        best_state_var=$current_state_var
    fi

    # Maj number of invariants
    echo "FIN WHILE"
    nb_invariants=$(./count_invariants.py $pwdd/total_invariants_$label.txt)
done