#!/usr/bin/env nix-shell
#!nix-shell -i python -p "python3.withPackages(p: with p; [pandas matplotlib numpy])"

import matplotlib.pyplot as plt
import math
import numpy as np
import re
import argparse
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument('-i', dest='input', action='store', required = True)
parser.add_argument('-o', dest='output', action='store', required = True)
parser.add_argument('--ref', dest='reference', action='store', required = True)
parser.add_argument('-r', dest='radius', action='store', type=float, required = True)


args = parser.parse_args()


def read_mtx(filename):
    size_reg = re.compile(r'(\d+)\s+(\d+)\s+(\d+)')
    value_reg = re.compile(r'(\d+)\s+(\d+)\s+([\d.,e+-]+)\s+(([\d.,e+-]+))')
    result = None
    with open(filename) as f:
        for idx, line in enumerate(f.readlines()):
            if idx == 0:
                continue
            if idx == 1:
                height = int(size_reg.match(line).group(1))
                width = int(size_reg.match(line).group(2))
                result = np.zeros((height, width), dtype=np.cdouble)
            if idx > 1:
                m = value_reg.match(line)
                row = int(m.group(1)) - 1
                col = int(m.group(2)) - 1
                real = float(m.group(3))
                imag = float(m.group(4))

                result[row, col] = complex(real, imag)
    return result

step_size = 0.01

ref_data = read_mtx(args.reference)
try:
    cim_data = read_mtx(args.input)

    print(cim_data)

    pd.DataFrame({'real': ref_data.real.flatten(), 'imag': ref_data.imag.flatten()}).to_csv('reference.csv')
    pd.DataFrame({'real': cim_data.real.flatten(), 'imag': cim_data.imag.flatten()}).to_csv('cim.csv')
except: pass

#fig, ax = plt.subplots(figsize=(6,6), dpi = 66)

#ax.plot(
    #ref_data.real,
    #ref_data.imag,
    #linestyle = '',
    #marker = 'o',
    #label = 'Eigenvalues by Octave'
#)
#ax.plot(
    #cim_data.real,
    #cim_data.imag,
    #linestyle = '',
    #marker = 'x',
    #label = 'Eigenvalues by Contour Integral Method'
#)

#radius = args.radius
#center = complex(0, 0)

#ax.plot(
    #[radius*math.cos(phi) + center.real for phi in np.arange(0, 2*math.pi, step_size)],
    #[radius*math.sin(phi) + center.imag for phi in np.arange(0, 2*math.pi, step_size)],
    #linestyle = ':',
    #label = 'Contour'
#)

#ax.set_xlim([-2, 2])
#ax.set_ylim([-2, 2])
#ax.set_xlabel('Real')
#ax.set_ylabel('Imaginary')
#ax.legend()
#fig.tight_layout()

#fig.savefig(args.output)