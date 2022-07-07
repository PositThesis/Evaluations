#!/usr/bin/env python

import os
import sys
import time
import argparse
from concurrent.futures import ThreadPoolExecutor

parser = argparse.ArgumentParser()
parser.add_argument('-i', dest='matrices', action='append', required = True)
parser.add_argument('-o', dest='output_dir', action='store', required = True)
parser.add_argument('-r', dest='radius', action='store', required = True)

args = parser.parse_args()

print(args)

def run(ty, points, radius, matrices, output):
    try:
        os.makedirs(f'{output}/{points}')
    except:
        pass
    input_args = '-i ' + ' -i '.join(matrices)
    print(f'CIMUSE_{ty} -p {num_points} -r {radius} -t poly {input_args} -o {output}/{points}/{ty}')
    os.system(f'CIMUSE_{ty} -p {num_points} -r {radius} -t poly {input_args} -o {output}/{points}/{ty} -cr 0.0 -ci 0.0')
    return f'{ty} finished'

for ty in ['Float', 'Double', 'LongDouble', 'Posit162', 'Posit322', 'Posit644']:
    if 'Posit' in ty: continue
    for num_points in range(3, 1000):
        # after 50: only do every second
        if num_points > 50 and num_points % 2 != 0:
            continue
        # after 100: only do every fourth
        if num_points > 100 and num_points % 4 != 0:
            continue
        # every eigth after 200
        if num_points > 200 and num_points % 8 != 0:
            continue
        # every sixteenth after 400
        if num_points > 400 and num_points % 16 != 0:
            continue
        print(f'running {num_points} points')
        run(ty, num_points, args.radius, args.matrices, args.output_dir)