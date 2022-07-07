#!/usr/bin/env python

import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor

def run(algorithm, ty, matrix, vector, output, tolerance, max_iters=-1):
    print(f'executing result/bin/{ty}{algorithm} {filename} {tolerance} {max_iters}')
    os.system(f'result/bin/{ty}{algorithm} -im {matrix} -iv {vector} -tol {tolerance} -o {output}/{algorithm}_{ty} -max_iter {max_iters}')
    return f'{ty} {algorithm} finished'

with ThreadPoolExecutor(max_workers=4) as e:
    futures = []

    for algorithm in ['GMRES', 'QMR', 'QMRWLA']:
        for ty in ['Float', 'Double', 'LongDouble', 'Posit162', 'Posit322', 'Posit644']:
            if algorithm == 'QMR' and ty in ['Float', 'Posit162']:
                continue
            futures.append(e.submit(run, algorithm, ty, sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5] if len(sys.argv) == 6 else -1))

    futures_done = 0
    while futures_done < len(futures):
        futures_done = len([future for future in futures if future.done()])
        print(f'{futures_done} / {len(futures)} done', end='\r')

        time.sleep(5)
