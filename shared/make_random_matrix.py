import random
import sys
import argparse
import numpy as np

parser = argparse.ArgumentParser()
parser.add_argument('--rows', dest='rows', action='store', type=int, required = True)
parser.add_argument('--cols', dest='cols', action='store', type=int, required = True)
parser.add_argument('-c', dest='complex', action='store_true')
parser.add_argument('-s', dest='seed', action='store', type=int, required = True)
parser.add_argument('-m', dest='magnitude', action='store', type=float, required = True)
parser.add_argument('-o', dest='output', action='store', type=str, required = True)
parser.add_argument('-band', dest='band', action='store', type=int)
args = parser.parse_args()

rng = np.random.default_rng(args.seed)

with open(args.output, 'w') as f:
    f.write(f'# random matrix with seed: {args.seed}\n')
    f.write(f'{args.rows} {args.cols} {args.rows * args.cols}\n')
    for row in range(args.rows):
        for col in range(args.cols):
            if args.band is not None:
                if not abs(row - col) < args.band:
                    continue
            if args.complex:
                f.write(f'{row+1} {col+1} {args.magnitude*(rng.random()-0.5)} {args.magnitude*(rng.random()-0.5)}\n')
            else:
                f.write(f'{row+1} {col+1} {args.magnitude*(rng.random()-0.5)}\n')