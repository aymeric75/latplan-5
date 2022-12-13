#!/usr/bin/env python3


import argparse
parser = argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter,
                                 description="load init/goal image files, normalize it, add noise, unnormalize it and plot. This script is used for generating some example figures in the paper.")
parser.add_argument("problem_dir", help="pathname to a directory containing init.png and goal.png")
parser.add_argument("network_dir", help="pathname to a directory containing the network")
args = parser.parse_args()


import subprocess
import os
import sys
import latplan
import latplan.model
from latplan.util import *
from latplan.util.planner import *
from latplan.util.plot import *
from latplan.util.noise import gaussian
import latplan.util.stacktrace
import os.path
import keras.backend as K
import tensorflow as tf
import math
import time
import json
import imageio


import numpy as np



# domainfile="samples/puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2/logs/05-06T16:13:22.480/domain.pddl"
# problem_dir="problem-generators/backup-propositional/vanilla/puzzle-mnist-3-3/007-000"








def main(problem_dir, network_dir):

        
    sae = latplan.model.load(network_dir, allow_failure=True)



    def load_image(name):

        image = imageio.imread(problem_dir+name+".png") / 255 # values are now between 0 and 1
        if len(image.shape) == 2:
            image = image.reshape(*image.shape, 1)
        image = sae.output.normalize(image) 
        return image



    sigma=0.1

    for name in ['init', 'goal']:

        image0 = load_image(name)
        im = gaussian(image0, sigma) #
        im = sae.output.unnormalize(im) # render the image (from the encoding ?)
        im = np.clip(im, 0, 1) # clip between 0 and 1
        im = im*255 # the real unnormalize ?
        im = im.astype(np.uint8)
        imageio.imsave(problem_dir+"{name}-{sigma}.png", im)







if __name__ == '__main__':
    try:
        main(**vars(args))
    except:
        import latplan.util.stacktrace
        latplan.util.stacktrace.format()