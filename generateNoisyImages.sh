#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
#SBATCH --partition=g100_usr_interactive
#SBATCH --account=uBS21_InfGer_0
#SBATCH --time=00:30:00
#SBATCH --mem=32G


# problems_dir=problem-generators/backup-propositional/vanilla/puzzle-mnist-3-3
problems_dir=problem-generators/backup-propositional/vanilla/puzzle-mandrill-4-4
# problems_dir=problem-generators/backup-propositional/vanilla/prob-cylinders-4
# problems_dir=problem-generators/backup-propositional/vanilla/lightsout-digital-5
# problems_dir=problem-generators/backup-propositional/vanilla/lightsout-twisted-5
# problems_dir=problem-generators/backup-propositional/vanilla/sokoban_2-False



# problems_dir=problem-generators/backup-propositional/vanilla/puzzle_longest-mnist-3-3
# problems_dir=problem-generators/backup-propositional/vanilla/puzzle_random_goal-mnist-3-3
# problems_dir=problem-generators/backup-propositional/vanilla/sokoban_pddl-2-False



# domain_file=samples/puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2/logs/05-06T11:21:55.052/domain.pddl
domain_file=samples/puzzle_mandrill_4_4_20000_CubeSpaceAE_AMA4Conv_kltune2/logs/05-06T11:21:53.162/domain.pddl
# domain_file=samples/blocks_cylinders-4-flat_20000_CubeSpaceAE_AMA4Conv_kltune2/logs/05-06T11:28:54.877/domain.pddl
# domain_file=samples/lightsout_digital_5_5000_CubeSpaceAE_AMA4Conv_kltune2/logs/05-06T11:21:56.828/domain.pddl
# domain_file=samples/lightsout_twisted_5_5000_CubeSpaceAE_AMA4Conv_kltune2/logs/05-06T11:21:58.468/domain.pddl
# domain_file=samples/sokoban_sokoban_image-20000-global-global-2-train_20000_CubeSpaceAE_AMA4Conv_kltune2/logs/05-09T16:42:26.372/domain.pddl


for dir_prob in $problems_dir/*/
do

    current_problems_dir=${dir_prob%*/}
    echo $dir_prob

    ./ama3-noise-plot.py $domain_file $dir_prob

done