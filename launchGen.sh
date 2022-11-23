#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
#SBATCH --partition=g100_usr_interactive
#SBATCH --account=uBS21_InfGer_0
#SBATCH --time=08:00:00
#SBATCH --mem=32G

## PUZZLE MNIST
#SBATCH --error=myJobMeta_mnistGen.err
#SBATCH --output=myJobMeta_mnistGen.out
task="puzzle"
type="mnist"
width_height="3 3"
nb_examples="5000"
label="mnist"
after_sample="puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2"
pb_subdir="puzzle-mnist-3-3"

rep_model="05-06T11:21:57.660"



domain=samples/$after_sample/logs/$rep_model/domain.pddl
path_to_repertoire=samples/$after_sample/logs/$rep_model
problem_file="ama3_samples_${after_sample}_logs_${rep_model}_domain_blind_problem.pddl"
problems_dir=problem-generators/backup-propositional/vanilla/$pb_subdir



current_problems_dir=$problems_dir/007-000


pwdd=$(pwd)




# train
./train_kltune.py resume $task $type $width_height $nb_examples CubeSpaceAE_AMA4Conv kltune2 $rep_model

