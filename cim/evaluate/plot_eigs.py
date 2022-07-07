#!/usr/bin/env nix-shell
#!nix-shell -i python -p "python3.withPackages(p: with p; [pandas matplotlib numpy])"

import matplotlib.pyplot as plt
import math
import numpy as np
import re
import argparse

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
cim_data = read_mtx(args.input)

plt.plot(
    ref_data.real,
    ref_data.imag,
    linestyle = '',
    marker = 'o'
)
plt.plot(
    cim_data.real,
    cim_data.imag,
    linestyle = '',
    marker = 'x'
)

radius = args.radius
center = complex(0, 0)

plt.plot(
    [radius*math.cos(phi) + center.real for phi in np.arange(0, 2*math.pi, step_size)],
    [radius*math.sin(phi) + center.imag for phi in np.arange(0, 2*math.pi, step_size)],
    linestyle = ':'
)

plt.xlim([-2, 2])
plt.ylim([-2, 2])

plt.savefig(args.output)