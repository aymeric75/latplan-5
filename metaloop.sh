#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
#SBATCH --partition=g100_usr_interactive
#SBATCH --account=uBS21_InfGer_0
#SBATCH --time=08:00:00
#SBATCH --mem=32G

# ## PUZZLE MNIST
# #SBATCH --error=myJobMeta_mnist.err
# #SBATCH --output=myJobMeta_mnist.out
# task="puzzle"
# type="mnist"
# width_height="3 3"
# nb_examples="5000"
# label="mnist"
# after_sample="puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2"
# pb_subdir="puzzle-mnist-3-3"


# ## PUZZLE MANDRILL
# #SBATCH --error=myJobMeta_mandrill.err
# #SBATCH --output=myJobMeta_mandrill.out
# task="puzzle"
# type="mandrill"
# width_height="4 4"
# nb_examples="20000"
# label="mandrill"
# after_sample="puzzle_mandrill_4_4_20000_CubeSpaceAE_AMA4Conv_kltune2"
# pb_subdir="puzzle-mandrill-4-4"



# BLOCKS
#SBATCH --error=myJobMeta_blocks.err
#SBATCH --output=myJobMeta_blocks.out
task="blocks"
type="cylinders-4-flat"
width_height=""
nb_examples="20000"
label="blocks"
after_sample="blocks_cylinders-4-flat_20000_CubeSpaceAE_AMA4Conv_kltune2"
pb_subdir="prob-cylinders-4"


# # LIGHTSOUT DIGITAL
# #SBATCH --error=myJobMeta_lightsdigital.err
# #SBATCH --output=myJobMeta_lightsdigital.out
# task="lightsout"
# type="digital"
# width_height="5"
# nb_examples="5000"
# label="lightsdigital"
# after_sample="lightsout_digital_5_5000_CubeSpaceAE_AMA4Conv_kltune2"
# pb_subdir="lightsout-digital-5"

# # LIGHTSOUT TWISTED
# #SBATCH --error=myJobMeta_lightstwisted.err
# #SBATCH --output=myJobMeta_lightstwisted.out
# task="lightsout"
# type="twisted"
# width_height="5"
# nb_examples="5000"
# label="lightstwisted"
# after_sample="lightsout_twisted_5_5000_CubeSpaceAE_AMA4Conv_kltune2"
# pb_subdir="lightsout-twisted-5"


# # SOKOBAN
# #SBATCH --error=myJobMeta_sokoban.err
# #SBATCH --output=myJobMeta_sokoban.out
# task="sokoban"
# type="sokoban_image-20000-global-global-2-train"
# width_height=""
# nb_examples="20000"
# label="sokoban"
# after_sample="sokoban_sokoban_image-20000-global-global-2-train_20000_CubeSpaceAE_AMA4Conv_kltune2"
# pb_subdir="sokoban-2-False"

# write in:
#    
#     extracted_mutexes_ 
#     variance.txt
#     omega_$label
#     total_invariants_$label


pwdd=$(pwd)



######################
##     Functions    ##
######################


# generate extracted_mutexes_* and put it in root
generate_invariants () {

    ### generate PDDL problem (with preconditions)
    ./ama3-planner.py $domain $current_problems_dir blind "" # replace "-1.0" with 

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
    echo "#" > current_invariant.txt
    sed -n '2p' extracted_mutexes_$label.txt >> current_invariant.txt
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
        ./train_kltune.py learn $task $type $width_height $nb_examples CubeSpaceAE_AMA4Conv kltune2 $rep_model $label
        produce_report
        echo "the invariant tested:"
        cat current_invariant.txt >> omega_$label.txt
        write_to_omega
        ((counter++))
    done
}



test_all_invariants_at_once() {

    # retrain fresh (par défaut, c'est bon) with the invariant (current_invariant.txt must be filled)
    ./train_kltune.py learn $task $type $width_height $nb_examples CubeSpaceAE_AMA4Conv kltune2 $rep_model $label
    produce_report
    echo "the invariant(s) tested:" >> omega_$label.txt
    cat invariants_to_test_$label.txt >> omega_$label.txt
    write_to_omega

}



echo "Start" > omega_$label.txt

# loop over the configs
for dir_conf in samples/$after_sample/logs/*/
do

    rep_model=$(basename $dir_conf)
    domain=samples/$after_sample/logs/$rep_model/domain.pddl
    path_to_repertoire=samples/$after_sample/logs/$rep_model
    problem_file="ama3_samples_${after_sample}_logs_${rep_model}_domain_blind_problem.pddl"
    problems_dir=problem-generators/backup-propositional/vanilla/$pb_subdir


    # write the name of the config dir
    echo "Dir_conf: $rep_model" >> omega_$label.txt


    ####################################
    # PHASE ONLY WITH EXISTING WEIGHTS #
    ####################################
    # Loop over the problems, once it found invs, test them, then break and go to PHASE 2

    echo "BEFORE DUMP"
    ### generate the actions
    ./train_kltune.py dump $task $type $width_height $nb_examples CubeSpaceAE_AMA4Conv kltune2 $rep_model
    echo "AFTER DUMP"

    ### generate PDDL domain
    ./pddl-ama3.sh $path_to_repertoire
    echo "AFTER GENERATE PDDL"


    produce_report
    write_to_omega

    found_invs=0

    for dir_prob in $problems_dir/*/
    do
        if [ $found_invs -eq 1 ]
        then
            break 2
        fi

        current_problems_dir=${dir_prob%*/} # Used in generate_invariants !

        # write the name of the prob dir
        echo "Dir_Prob: $(basename $dir_prob)" >> omega_$label.txt

        ## generate invariants from the fresh copy
        generate_invariants

        nb_invariants_prob=$(./count_invariants.py $pwdd/extracted_mutexes_$label.txt)

        ## if invariants found # TEST all invariants at ONCE
        if [ $nb_invariants_prob -gt 0 ]
        then
            found_invs=1
            echo "Invariants found (taking the author's released weights) !" >> omega_$label.txt
            cat $pwdd/extracted_mutexes_$label.txt >> omega_$label.txt
            cat $pwdd/extracted_mutexes_$label.txt > invariants_to_test_$label.txt
            echo "Re-training LatPlan with these invariants" >> omega_$label.txt
            # Test the effect of all the invariant at once (one training + produce report)
            test_all_invariants_at_once

            ### TEST without the invariants: in order to compare
            echo "now retraining without the invariants, for comparison" >> omega_$label.txt
            rm invariants_to_test_$label.txt
            ./train_kltune.py learn $task $type $width_height $nb_examples CubeSpaceAE_AMA4Conv kltune2 $rep_model $label
            produce_report
            write_to_omega

        else
            echo "No training, no invariants found" >> omega_$label.txt
        fi

    done

    

    # ################################################################ #
    # # PHASE RETRAINING THE MODEL (without calling author's weights # #
    # ################################################################ #
   
    # No need to do anything with the weight files... we will not load them and then
    # we override them...
    # retrain the network ONCE
    # THEN go over the prob dirs (same as before, if find invs, test them THEN break)


    rm invariants_to_test_$label.txt

    ## train
    ./train_kltune.py learn $task $type $width_height $nb_examples CubeSpaceAE_AMA4Conv kltune2 $rep_model

    ### generate the actions
    ./train_kltune.py dump $task $type $width_height $nb_examples CubeSpaceAE_AMA4Conv kltune2 $rep_model

    ### generate PDDL domain
    ./pddl-ama3.sh $path_to_repertoire

    produce_report
    write_to_omega


    found_invs=0

    for dir_prob in $problems_dir/*/
    do
        if [ $found_invs -eq 1 ]
        then
            break 2
        fi

        current_problems_dir=${dir_prob%*/} # Used in generate_invariants !

        # write the name of the prob dir
        echo "Dir_Prob: $(basename $dir_prob)" >> omega_$label.txt

        ## generate invariants from the re-trained LatPlan
        generate_invariants

        nb_invariants_prob=$(./count_invariants.py $pwdd/extracted_mutexes_$label.txt)

        ## if invariants found # TEST all invariants at ONCE
        if [ $nb_invariants_prob -gt 0 ]
        then
            found_invs=1
            echo "Invariants found (NOT taking the author's released weights) !"
            cat $pwdd/extracted_mutexes_$label.txt >> omega_$label.txt
            cat $pwdd/extracted_mutexes_$label.txt > invariants_to_test_$label.txt
            echo "Re-training LatPlan with these invariants"
            # Test the effect of all the invariant at once (one training + produce report)
            test_all_invariants_at_once
        else
            echo "No training, no invariants found" >> omega_$label.txt
        fi

    done

done




