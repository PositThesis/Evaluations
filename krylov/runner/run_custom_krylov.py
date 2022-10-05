#!/usr/bin/env python

import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-im', dest='matrix', action='store', required = True)
parser.add_argument('-iv', dest='vector', action='store', required = True)
parser.add_argument('-o', dest='output_dir', action='store', required = True)
parser.add_argument('-iters', dest='iters', type=int, action='store', required = True)
parser.add_argument('-restart', dest='restart', type=int, default=-1, action='store')
parser.add_argument('-hh', dest='hh', action='store_true', default=False)
parser.add_argument('-eigen_like', dest='eigen_like', action='store_true', default=False)
parser.add_argument('-sparse', dest='sparse', action='store_true', default=False)

args = parser.parse_args()

def run(algorithm, ty):
    command = f'{ty}{algorithm} -im {args.matrix} -iv {args.vector} -o {args.output_dir}/{algorithm}_{ty} -iters {args.iters}'
    if args.restart > 0:
        command += f' -restart {args.restart}'
    if args.hh:
        command += f' -hh'
    if args.eigen_like:
        command += f' -eigen_like'
    if args.sparse:
        command += f' -sparse'

    print(f'running command: "{command}"')
    os.system(command)
    return f'{ty} {algorithm} finished'

with ThreadPoolExecutor(max_workers=1) as e:
    futures = []

    for algorithm in ['GMRES', 'QMR', 'QMRWLA']:
        for ty in ['Float', 'Double', 'LongDouble', 'Posit16', 'Posit32', 'Posit64']:
            futures.append(e.submit(run, algorithm, ty))

    futures_done = 0
    while futures_done < len(futures):
        futures_done = len([future for future in futures if future.done()])
        print(f'{futures_done} / {len(futures)} done', end='\r')

        time.sleep(5)
