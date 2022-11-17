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

nb_pbs_test='101'

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
    sed -i '1,3d' $pwdd/total_invariants_$label.txt
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



for dir0 in samples/$after_sample/logs/*/
do   

    echo "current dir"
    echo $dir0

    export rep_model=$(basename $dir0)
    export domain=samples/$after_sample/logs/$rep_model/domain.pddl
    export path_to_repertoire=samples/$after_sample/logs/$rep_model
    export problem_file="ama3_samples_${after_sample}_logs_${rep_model}_domain_blind_problem.pddl"
    export problems_dir=problem-generators/backup-propositional/vanilla/$pb_subdir

    counter=0



    for dir in $problems_dir/*/     #
    do
      

        ((counter++))
        if [[ "$counter" == $nb_pbs_test ]]
        then
            break
        fi

        current_problems_dir=${dir%*/}

        echo "current problem dir"
        echo $current_problems_dir

        # #############################################################################################
        ## Compute metrics and store them in vars and files                                           #
        # #############################################################################################
        produce_report
        best_state_var=$current_state_var

        # generate the invariants
        generate_invariants

        # nb_invariants_last is the # of invariants to be tested in the current dir and dir0
        # count invariants
        nb_invariants_last=$(./count_invariants.py $pwdd/extracted_mutexes_$label.txt)

        # sentence if no invariants found directly
        sentence_if_invariants="invariants found without training for prob: $dir0, subprob: $current_problems_dir"

        # if no invariants, retrain
        if [ $nb_invariants_last -eq 0 ] && [[ "$counter" == '0' ]]
        then

            ./train_kltune.py learn $task $type $width_height $nb_examples CubeSpaceAE_AMA4Conv kltune2 $rep_model

            # try to generate the invariants again
            generate_invariants

            # re count
            nb_invariants_last=$(./count_invariants.py $pwdd/extracted_mutexes_$label.txt)

            # if nb invariants is still 0
            if [ $nb_invariants_last -eq 0 ]
            then
                sentence_no_invariants="no invariants found, even after training prob: $dir0, subprob: $current_problems_dir"
                echo $sentence_no_invariants >> omega_$label.txt
                write_to_omega
                continue
            else
                sentence_if_invariants="invariants found after a first training prob: $dir0, subprob: $current_problems_dir"
            fi
        fi


        if [ $nb_invariants_last -eq 0 ] && [[ "$counter" != '0' ]]
        then
            sentence_no_invariants="no invariants found, even after training prob: $dir0, subprob: $current_problems_dir"
            echo $sentence_no_invariants >> omega_$label.txt
            write_to_omega
            continue
        fi

        echo $sentence_if_invariants >> omega_$label.txt

        # Copy the invariants to omega
        cat extracted_mutexes_$label.txt >> omega_$label.txt

        # writing the metrics
        write_to_omega

        # storing the invariants in total_invariants + updating the nb_invariant variable
        cp $pwdd/extracted_mutexes_$label.txt $pwdd/total_invariants_$label.txt
        # nb_invariants_last=$(./count_invariants.py $pwdd/total_invariants_$label.txt)


        # while there are still invariants in total_invariants_$label.txt
        while [ $nb_invariants_last -gt 0 ]
        do
            echo "IN WHILE !"

            # Update current_invariant.txt (there are only 2 lines in this file)
            extract_current_invariant

            # Remove from total_invariants_$label.txt
            remove_current_invariant

            # Each training is COMPLETLY NEW (even the loss function), we use the invariant from current_invariant.txt
            ./train_kltune.py learn $task $type $width_height $nb_examples CubeSpaceAE_AMA4Conv kltune2 $rep_model

            ## Once trained, update the metrics variables
            cd $pwdd
            produce_report
            

            # Update Omega
            echo "#" >> omega_$label.txt
            echo "current invariant:" >> omega_$label.txt
            cat current_invariant.txt >> omega_$label.txt
            write_to_omega


            # If current_state_var <= best_so_far, we try to generate new invariants from this training !

            comparison=$(./a_inf_b.py $current_state_var $best_state_var) # nb1 <= nb2

            if [ $comparison -eq 1 ]
            then
                echo "found better or equal variance"
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
            nb_invariants_last=$(./count_invariants.py $pwdd/total_invariants_$label.txt)
        done
    done

done




