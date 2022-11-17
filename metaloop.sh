#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
#SBATCH --partition=g100_usr_interactive
#SBATCH --account=uBS21_InfGer_0
#SBATCH --time=08:00:00
#SBATCH --mem=32G

## PUZZLE MNIST
#SBATCH --error=myJobMeta_mnist.err
#SBATCH --output=myJobMeta_mnist.out
task="puzzle"
type="mnist"
width_height="3 3"
nb_examples="5000"
export label="mnist"
export after_sample="puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2"
export pb_subdir="puzzle-mnist-3-3"

echo "ICI "

# ## PUZZLE MANDRILL
# #SBATCH --error=myJobMeta_mandrill807.err
# #SBATCH --output=myJobMeta_mandrill807.out
# task="puzzle"
# type="mandrill"
# width_height="4 4"
# nb_examples="20000"
# export label="mandrill807"
# export after_sample="puzzle_mandrill_4_4_20000_CubeSpaceAE_AMA4Conv_kltune2"
# export pb_subdir="puzzle-mandrill-4-4"

# # BLOCKS
# #SBATCH --error=myJobMeta_blocks809.err
# #SBATCH --output=myJobMeta_blocks809.out
# task="blocks"
# type="cylinders-4-flat"
# width_height=""
# nb_examples="20000"
# export label="blocks809"
# export after_sample="blocks_cylinders-4-flat_20000_CubeSpaceAE_AMA4Conv_kltune2"
# export pb_subdir="prob-cylinders-4"


# # LIGHTSOUT DIGITAL
# #SBATCH --error=myJobMeta_lightsdigital335.err
# #SBATCH --output=myJobMeta_lightsdigital335.out
# task="lightsout"
# type="digital"
# width_height="5"
# nb_examples="5000"
# export label="lightsdigital335"
# export after_sample="lightsout_digital_5_5000_CubeSpaceAE_AMA4Conv_kltune2"
# export pb_subdir="lightsout-digital-5"

# # LIGHTSOUT TWISTED
# #SBATCH --error=myJobMeta_lightstwisted348.err
# #SBATCH --output=myJobMeta_lightstwisted348.out
# task="lightsout"
# type="twisted"
# width_height="5"
# nb_examples="5000"
# export label="lightstwisted348"
# export after_sample="lightsout_twisted_5_5000_CubeSpaceAE_AMA4Conv_kltune2"
# export pb_subdir="lightsout-twisted-5"


# # SOKOBAN
# #SBATCH --error=myJobMeta_sokoban372.err
# #SBATCH --output=myJobMeta_sokoban372.out
# task="sokoban"
# type="sokoban_image-20000-global-global-2-train"
# width_height=""
# nb_examples="20000"
# export label="sokoban372"
# export after_sample="sokoban_sokoban_image-20000-global-global-2-train_20000_CubeSpaceAE_AMA4Conv_kltune2"
# export pb_subdir="sokoban-2-False"

# write in:
#    
#     extracted_mutexes_ 
#     variance.txt
#     omega_$label
#     total_invariants_$label


pwdd=$(pwd)


export best_state_var=99


######################
##     Functions    ##
######################


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



# from extracted_mutexes_*.txt to current_invariant.txt (in root)
extract_current_invariant() {
    sed -n '2p' extracted_mutexes_$label.txt > current_invariant.txt
    sed -n '3p' extracted_mutexes_$label.txt >> current_invariant.txt
}

# remove current invariant from total_invariants_*.txt (in root)
remove_current_invariant() {
    sed -i '1,3d' $pwdd/extracted_mutexes_$label.txt
}

#  store metrics in bash variables
produce_report() {
    ./train_kltune.py report $task $type $width_height $nb_examples CubeSpaceAE_AMA4Conv kltune2 $rep_model
    current_state_var=$(sed '1q;d' $pwdd/$path_to_repertoire/variance.txt)
    current_elbo=$(sed '2q;d' $pwdd/$path_to_repertoire/variance.txt)
    current_next_state_pred=$(sed '3q;d' $pwdd/$path_to_repertoire/variance.txt)
    current_true_num_actions=$(sed '4q;d' $pwdd/$path_to_repertoire/variance.txt)
}

# write metrics in omega_*.txt
write_to_omega() {
    echo "state_var: $current_state_var" >> omega_$label.txt
    echo "elbo: $current_elbo" >> omega_$label.txt
    echo "next_state_pred: $current_next_state_pred" >> omega_$label.txt
    echo "num_actions: $current_true_num_actions" >> omega_$label.txt
}



loop_over_invariants() {
    nb_invariants_curr=$nb_invariants_prob
    counter=1
    until [ $counter -gt $nb_invariants_curr ] 
    do
        extract_current_invariant
        remove_current_invariant
        # retrain fresh (par défaut, c'est bon) with the invariant (current_invariant.txt must be filled)
        ./train_kltune.py learn $task $type $width_height $nb_examples CubeSpaceAE_AMA4Conv kltune2 $rep_model
        produce_report
        echo "the invariant tested:"
        cat current_invariant.txt >> omega_$label.txt
        write_to_omega
        ((counter++))
    done
}


# loop over the configs
for dir_conf in samples/$after_sample/logs/*/
do

    export rep_model=$(basename $dir_conf)
    export domain=samples/$after_sample/logs/$rep_model/domain.pddl
    export path_to_repertoire=samples/$after_sample/logs/$rep_model
    export problem_file="ama3_samples_${after_sample}_logs_${rep_model}_domain_blind_problem.pddl"
    export problems_dir=problem-generators/backup-propositional/vanilla/$pb_subdir


    # write the name of the config dir
    echo "Dir_conf: $rep_model" >> omega_$label.txt


    # make a fresh copy of net0.h5 (we use it after)
    cp $path_to_repertoire/net0.h5 $path_to_repertoire/net0-real.h5

    count_pb=0

    # loop over the problems
    for dir_prob in $problems_dir/*/
    do

        current_problems_dir=${dir_prob%*/}

        # write the name of the prob dir
        echo "Dir_Prob: $(basename $dir_prob)" >> omega_$label.txt

        # retrieve a fresh copy of net0.h5
        cp $path_to_repertoire/net0-real.h5 $path_to_repertoire/net0.h5

        ####################################
        # PHASE ONLY WITH EXISTING WEIGHTS #
        ####################################

        ## generate invariants from the fresh copy
        generate_invariants
        nb_invariants_prob=$(./count_invariants.py $pwdd/extracted_mutexes_$label.txt)

        ## if invariants found
        if [ $nb_invariants_prob -gt 0 ]
        then
            echo "Invariants found (taking the author's released weights) !"
            cat $pwdd/extracted_mutexes_$label.txt >> omega_$label.txt
            ## loop over invariants (i.e. train for each invariant, and write to omega)
            loop_over_invariants
        else
            echo "No training, no invariants found" >> omega_$label.txt
        fi

        ##############################
        # PHASE RETRAINING THE MODEL #
        ##############################
        
        # we train only for the first prob_dir (the other trainings would have been the exact same)
        if [[ $count_pb -eq 0 ]]

        then
            # we rm it to be sure no invariant is taken into account during training
            rm current_invariant.txt

            ## train
            ./train_kltune.py learn $task $type $width_height $nb_examples CubeSpaceAE_AMA4Conv kltune2 $rep_model
            generate_invariants
            nb_invariants_prob=$(./count_invariants.py $pwdd/extracted_mutexes_$label.txt)

            ## if invariants found
            if [ $nb_invariants_prob -gt 0 ]
            then
                echo "Invariants found (after training) !"
                cat $pwdd/extracted_mutexes_$label.txt >> omega_$label.txt
                ## loop over invariants and write to omega
                loop_over_invariants
            else
                echo "ONE training, no invariants FOUND" >> omega_$label.txt
            fi
        
        fi

        ((count_pb++))

    done

done




