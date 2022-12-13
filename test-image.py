#!/usr/bin/env python3

import argparse
# parser = argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter,
#                                  description="load init/goal image files, normalize it, add noise, unnormalize it and plot. This script is used for generating some example figures in the paper.")
# parser.add_argument("domainfile", help="pathname to a PDDL domain file")
# parser.add_argument("problem_dir", help="pathname to a directory containing init.png and goal.png")
# args = parser.parse_args()


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
float_formatter = lambda x: "%.3f" % x
np.set_printoptions(threshold=sys.maxsize,formatter={'float_kind':float_formatter})

#domainfile="/g100_work/uBS21_InfGer_0/latplan-5.0.0/samples/puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2/logs/05-06T16:13:22.480/domain.pddl"
domainfile="samples/puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2/logs/05-06T16:13:22.480/domain.pddl"

#problem_dir="/g100_work/uBS21_InfGer_0/latplan-5.0.0/problem-generators/backup-propositional/vanilla/puzzle-mnist-3-3/007-000"

problem_dir="problem-generators/backup-propositional/vanilla/puzzle-mnist-3-3/007-000"

network_dir = os.path.dirname(domainfile)
domainfile_rel = os.path.relpath(domainfile, network_dir)

def domain(path):
    dom_prefix = domainfile_rel.replace("/","_")
    root, ext = os.path.splitext(path)
    return "{}_{}{}".format(os.path.splitext(dom_prefix)[0], root, ext)

log("loaded puzzle")
sae = latplan.model.load(network_dir,allow_failure=True)
log("loaded sae")
setup_planner_utils(sae, problem_dir, network_dir, "ama3")

p = puzzle_module(sae)
log("loaded puzzle")

def load_image(name):
    image = imageio.imread(problem(f"{name}.png")) / 255 # values are now between 0 and 1
    if len(image.shape) == 2:
        image = image.reshape(*image.shape, 1)
    image = sae.output.normalize(image) 
    return image

for name in ("init", "goal"):
    image0 = load_image(name)
    print("IMAGE format")
    print(type(image0)) # <class 'imageio.core.util.Array'>  (48, 48, 1)
    print(image0.shape)
    for sigma in (100.0, 30.0, 10.0, 3.0, 1.0, 0.3, 0.1, 0.03):
        im = gaussian(image0, sigma) # 
        im = sae.output.unnormalize(im) # render the image (from the encoding ?)
        im = np.clip(im, 0, 1) # clip between 0 and 1
        im = im*255 # the real unnormalize ?
        im = im.astype(np.uint8)
        imageio.imsave(problem(f"{name}-{sigma}.png"), im)
