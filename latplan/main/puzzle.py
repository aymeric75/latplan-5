import numpy as np
import os.path
from ..util.tuning import parameters
from .common import *
from .normalization import normalize_transitions, normalize_transitions_objects
from . import common
from ..puzzles.objutil import bboxes_to_coord, random_object_masking, tiled_bboxes, image_to_tiled_objects
from ..util.stacktrace import format
import imageio


def load_puzzle(type,width,height,num_examples,objects=True,**kwargs):
    import importlib
    generator = 'latplan.puzzles.puzzle_{}'.format(type)
    parameters["generator"] = generator
    p = importlib.import_module(generator)
    p.setup()
    path = os.path.join(latplan.__path__[0],"puzzles","-".join(map(str,["puzzle",type,width,height]))+".npz")
    print("LOADDDDING PUZZ")
    with np.load(path) as data:
        pres_configs = data['pres'][:num_examples]
        sucs_configs = data['sucs'][:num_examples]


    print("000")
    print(pres_configs.shape)


    pres = p.states(width, height, pres_configs)[:,:,:,None]
    sucs = p.states(width, height, sucs_configs)[:,:,:,None]
    B, H, W, C = pres.shape
    parameters["picsize"]        = [[H,W]]
    print("loaded. picsize:",[H,W])

    print("111")
    print(pres.shape) # (5000, 48, 48, 1)


    ima = pres[0]

    imageio.imsave("theImage0.png", ima)


    # noisy_images must replace pres
    pres = np.random.normal(0, 0.3, pres.shape) + pres

    ima = pres[0]

    imageio.imsave("theImage1.png", ima)

    domainfile="samples/puzzle_mnist_3_3_5000_CubeSpaceAE_AMA4Conv_kltune2/logs/05-06T16:13:22.480/domain.pddl"
    problem_dir="problem-generators/backup-propositional/vanilla/puzzle-mnist-3-3/007-000"
    network_dir = os.path.dirname(domainfile)
    domainfile_rel = os.path.relpath(domainfile, network_dir)

    


    sae = latplan.model.load(network_dir,allow_failure=True)
    ima = sae.output.unnormalize(ima) # 
    ima = np.clip(ima, 0, 1) # clip between 0 and 1
    ima = ima*255 # the real unnormalize ?
    ima = ima.astype(np.uint8)

    print(ima)
    print("ima TYPE !!")
    exit()
    #imageio.imsave(problem(f"{name}-{sigma}.png"), im)





    if objects:
        pres = image_to_tiled_objects(pres, p.setting['base'])

        print("222")
        print(type(pres))


        sucs = image_to_tiled_objects(sucs, p.setting['base'])
        bboxes = tiled_bboxes(B, height, width, p.setting['base'])
        pres = np.concatenate([pres,bboxes], axis=-1)
        sucs = np.concatenate([sucs,bboxes], axis=-1)
        transitions, states = normalize_transitions_objects(pres,sucs,**kwargs)
    else:
        transitions, states = normalize_transitions(pres, sucs)
    return transitions, states


################################################################
# flat images

def puzzle(args):
    transitions, states = load_puzzle(**vars(args),objects=False)

    ae = run(os.path.join("samples",common.sae_path), transitions)


_parser = subparsers.add_parser('puzzle', formatter_class=argparse.ArgumentDefaultsHelpFormatter, help='Sliding tile puzzle.')
_parser.add_argument('type', choices=["mnist","mandrill","spider"], help='')
_parser.add_argument('width', type=int, default=3, help='Integer width of the puzzle. In MNIST, the value must be 3.')
_parser.add_argument('height', type=int, default=3, help='Integer height of the puzzle. In MNIST, the value must be 3.')
add_common_arguments(_parser,puzzle)

################################################################
# object-based representation

def puzzle_objs(args):
    transitions, states = load_puzzle(**vars(args))

    ae = run(os.path.join("samples",common.sae_path), transitions)

    transitions = transitions[:6]
    _,_,O,_ = transitions.shape
    print("plotting interpolation")
    for O2 in [ 3, 5, 7 ]:
        try:
            masked2 = random_object_masking(transitions,O2)
        except Exception as e:
            print(f"O2={O2}. Masking failed due to {e}, skip this iteration.")
            continue
        ae.reload_with_shape(masked2.shape[1:])
        plot_autoencoding_image(ae,masked2,f"interpolation-{O2}")

    pass


_parser = subparsers.add_parser('puzzle_objs', formatter_class=argparse.ArgumentDefaultsHelpFormatter, help='Object-based sliding tile puzzle.')
_parser.add_argument('type', choices=["mnist","mandrill","spider"], help='')
_parser.add_argument('width', type=int, default=3, help='Integer width of the puzzle. In MNIST, the value must be 3.')
_parser.add_argument('height', type=int, default=3, help='Integer height of the puzzle. In MNIST, the value must be 3.')
add_common_arguments(_parser,puzzle_objs,True)

