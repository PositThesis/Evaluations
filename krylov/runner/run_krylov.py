#!/usr/bin/env python

import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-im', dest='matrix', action='store', required = True)
parser.add_argument('-iv', dest='vector', action='store', required = True)
parser.add_argument('-tol', dest='tolerance', type=float, action='store', required = True)
parser.add_argument('-o', dest='output_dir', action='store', required = True)
parser.add_argument('-max_iter', dest='max_iter', type=int, action='store', required = True)
parser.add_argument('-restart', dest='restart', type=int, action='store', required = True)

args = parser.parse_args()

def run(algorithm, ty, matrix, vector, output_dir, tolerance, max_iters=-1, restart=-1):
    os.system(f'{ty}{algorithm} -im {matrix} -iv {vector} -tol {tolerance} -o {output_dir}/{algorithm}_{ty} -max_iter {max_iters} -restart {restart}')
    return f'{ty} {algorithm} finished'

with ThreadPoolExecutor(max_workers=4) as e:
    futures = []

    for algorithm in ['GMRES', 'QMR', 'QMRWLA']:
        for ty in ['Float', 'Double', 'LongDouble', 'Posit16', 'Posit32', 'Posit64']:
            # if algorithm == 'QMR' and ty in ['Float', 'Posit16']:
            #     continue
            # futures.append(e.submit(run, algorithm, ty, sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5] if len(sys.argv) == 6 else -1))
            futures.append(e.submit(run, algorithm, ty, args.matrix, args.vector, args.output_dir, args.tolerance, args.max_iter, args.restart))

    futures_done = 0
    while futures_done < len(futures):
        futures_done = len([future for future in futures if future.done()])
        print(f'{futures_done} / {len(futures)} done', end='\r')

        time.sleep(5)
