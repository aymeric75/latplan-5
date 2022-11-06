#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --error=myJob50.err
#SBATCH --output=myJob50.out
#SBATCH --gres=gpu:1
#SBATCH --partition=g100_usr_interactive
#SBATCH --account=uBS21_InfGer_0
#SBATCH --time=00:30:00
#SBATCH --mem=32G


#./train_kltune.py resume puzzle mnist 3 3 5000 CubeSpaceAE_AMA4Conv kltune2 "05-06T16:13:22.480"

#./train_kltune.py reproduce puzzle mnist 3 3 5000 CubeSpaceAE_AMA4Conv kltune2

#./train_kltune.py dump puzzle mnist 3 3 5000 CubeSpaceAE_AMA4Conv kltune2 "SomeTime47"

# ./train_kltune.py report puzzle mnist 3 3 5000 CubeSpaceAE_AMA4Conv kltune2 "05-06T11:21:55.052"

###################
## TRAIN the stuff from begining with MetaLearning
################### 
# > to load from a JSON file, put it in the hash path
# > to specify specific parameters (size of N ?): put it before in the code
./train_kltune.py learn puzzle mnist 3 3 5000 CubeSpaceAE_AMA4Conv kltune2 "SomeTime50"