#!/usr/bin/env python3


import subprocess
import os
import sys
import latplan
import latplan.model
from latplan.util import *
from latplan.util.planner import *
from latplan.util.plot import *
import latplan.util.stacktrace
import os.path
import keras.backend as K
import tensorflow as tf
import math
import time
import json

import numpy as np
float_formatter = lambda x: "%.3f" % x
np.set_printoptions(threshold=sys.maxsize,formatter={'float_kind':float_formatter})


def thefunc(domainfile, problem_dir, heuristics):
    cycle=1
    sigma=None
    network_dir = os.path.dirname(domainfile)
    domainfile_rel = os.path.relpath(domainfile, network_dir)
    
    def domain(path):
        dom_prefix = domainfile_rel.replace("/","_")
        root, ext = os.path.splitext(path)
        return "{}_{}{}".format(os.path.splitext(dom_prefix)[0], root, ext)
    def heur(path):
        root, ext = os.path.splitext(path)
        return "{}_{}{}".format(heuristics, root, ext)
    
    log("loaded puzzle")
    sae = latplan.model.load(network_dir,allow_failure=True)
    log("loaded sae")
    setup_planner_utils(sae, problem_dir, network_dir, "ama3")

    p = puzzle_module(sae)
    log("loaded puzzle")

    log(f"loading init/goal")
    init, goal = init_goal_misc(p, cycle, noise=sigma)
    log(f"loaded init/goal")

    log(f"start planning")

    bits = np.concatenate((init,goal))

    ###### files ################################################################
    ig          = problem(ama(network(domain(heur(f"problem.ig")))))
    problemfile = problem(ama(network(domain(heur(f"problem.pddl")))))
    planfile    = problem(ama(network(domain(heur(f"problem.plan")))))
    tracefile   = problem(ama(network(domain(heur(f"problem.trace")))))
    csvfile     = problem(ama(network(domain(heur(f"problem.csv")))))
    pngfile     = problem(ama(network(domain(heur(f"problem.png")))))
    jsonfile    = problem(ama(network(domain(heur(f"problem.json")))))
    logfile     = problem(ama(network(domain(heur(f"problem.log")))))
    npzfile     = problem(ama(network(domain(heur(f"problem.npz")))))
    negfile     = problem(ama(network(domain(heur(f"problem.negative")))))

    valid = False
    found = False
    try:
        ###### preprocessing ################################################################
        log(f"start generating problem")
        os.path.exists(ig) or np.savetxt(ig,[bits],"%d")
        echodo(["helper/ama3-problem.sh",ig,problemfile])



    finally:
        with open(jsonfile,"w") as f:
            parameters = sae.parameters.copy()
            del parameters["mean"]
            del parameters["std"]
            json.dump({
                "problem":os.path.normpath(problem_dir).split("/")[-1],             
                "problemfile":problemfile,
            }, f, indent=2)


