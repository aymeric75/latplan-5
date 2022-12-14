#!/usr/bin/env python3
# from numpy.random import seed
# seed(1)
# from tensorflow import set_random_seed
# set_random_seed(2)

import latplan.main
from train_common import parameters


parameters.update({
    'N'              :[50,100,300], # latent space size
    'zerosuppress'   :0.1,
    'beta_d'         :[ 1,10,100,1000,10000 ],
    'beta_z'         :[ 1,10 ],
})

if __name__ == '__main__':
    import tensorflow as tf
    import keras
    print("KERAS version")
    print(keras.__version__)
    print("TENSORFLOW version")
    print(tf. __version__) 
    print("IN TRAIN KLTUNE")
    latplan.main.main(parameters)
