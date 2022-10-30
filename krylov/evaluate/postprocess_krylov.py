#!/usr/bin/env nix-shell
#!nix-shell -i python -p "python3.withPackages(p: with p; [pandas matplotlib])"

import matplotlib.pyplot as plt
import matplotlib.colors as mc
import pandas as pd
import os
import sys
import math

import argparse
import colorsys

parser = argparse.ArgumentParser()
parser.add_argument('-i', dest='input', action='store', required = True)
parser.add_argument('-o', dest='output_dir', action='store', required = True)
parser.add_argument('-max_iter', dest='max_iter', type=int, action='store', required = True)
parser.add_argument('-tol', dest='tol', type=float, action='store', required = True)
parser.add_argument('-no_labels', dest='no_labels', action='store_true', default = False)
parser.add_argument('-fixed_colors', dest='fixed_colors', action='store_true', default = False)
parser.add_argument('-fixed_types', dest='fixed_types', action='store_true', default = False)
args = parser.parse_args()

algorithms = []
types = []

for f in os.listdir(args.input):
    print(f)
    algorithms.append(f.split('_')[0])
    types.append(f.split('_')[1].split('.')[0])

algorithms = list(dict.fromkeys(algorithms))
types = list(dict.fromkeys(types))
types.sort()
if args.fixed_types:
    types = ['Float', 'Double', 'LongDouble', 'Posit16', 'Posit32', 'Posit64']

figures = {
    alg: plt.subplots(1, 2, dpi=600, figsize=(14, 5))
    for alg in algorithms
}
start_idx = 0

for s_idx, solver in enumerate(algorithms):
    fig, axes = figures[solver]
    iter_ax = axes[0]
    iter_ax.set(
        title=f'{solver}',
        xlabel='Iterations',
        ylabel='Relative Residual',
        yscale="log",
        xlim=[0, args.max_iter],
        xscale="linear"
    )
    time_ax = axes[1]
    time_ax.set(
        xlabel='Iteration',
        ylabel='Time per Iteration [s]',
        yscale="log",
        xscale="linear",
        xlim=[0, args.max_iter],
    )
    min_res = 1
    min_time = 1
    max_time = 1
    # for color, num in [('tab:blue', 'Float'), ('tab:orange', 'Double'), ('tab:green', 'LongDouble'), ('tab:red', 'Posit16'), ('tab:purple', 'Posit32'), ('tab:brown', 'Posit64')]:
    colors = {
        'Float': 'tab:blue',
        'Double': 'tab:orange',
        'LongDouble': 'tab:green',
        'Posit16': 'tab:red',
        'Posit32': 'tab:purple',
        'Posit64': 'tab:brown'
    }
    def idx_to_color(idx, total):
        # if idx % 2 == 0:
        #     return colorsys.hsv_to_rgb((idx//2/total)*2 * 0.9, 1, 1)
        # else:
        #     return colorsys.hsv_to_rgb((idx//2/total)*2 * 0.9, 0.5, 1)
        if idx%2 == 0 or True:
            return list(mc.TABLEAU_COLORS.values())[idx//2]
        else:
            idx_half = idx//2
            a = mc.to_rgb(list(mc.TABLEAU_COLORS.values())[idx_half])
            b = mc.to_rgb(list(mc.TABLEAU_COLORS.values())[(idx_half + 1)%10]) # just to be sure...
            c = tuple((a_val + b_val)/2 for a_val, b_val in zip(a, b))
            return c
        
        
    for idx, num in enumerate(types):
        filename = f'{args.input}/{solver}_{num}.csv'
        if os.path.exists(filename):
            print(f'plotting {num}, {solver}')
            data = pd.read_csv(filename)
            # remove iterations above the max_iter limit. makes the time and iterations align
            data = data.loc[data.loc[:, 'iteration'] <= args.max_iter, :]

            time_ax.plot(data.loc[1:, 'iteration'], data.loc[:, 'time [μs]'].diff().loc[1:]/1e6, 1.0, color = idx_to_color(idx, len(types)) if not args.fixed_colors else colors[num], label = num, linestyle=':' if not args.fixed_colors and idx%2==1 else '-')
            
            # remove negative residuals. these are inserted when we skip certain iterations
            data = data.loc[data.loc[:, 'residual'] >= 0, :]
            iter_ax.plot(data.loc[:, 'iteration'], data.loc[:, 'residual'], 1.0, color = idx_to_color(idx, len(types)) if not args.fixed_colors else colors[num], label = "", linestyle=':' if not args.fixed_colors and idx%2==1 else '-')
            # time_ax.plot(data.loc[:, 'time [μs]']/1e6, data.loc[:, 'residual'], 1.0, label = num, linestyle='-')

            min_res = max(min(min_res, data.loc[:, 'residual'].min()), args.tol)
            min_time = min(min_time, (data.loc[:, 'time [μs]'].diff().loc[1:]/1e6).min())
            max_time = max(max_time, (data.loc[:, 'time [μs]'].diff().loc[1:]/1e6).max())
        else:
            print(f'{filename} not found')

    lower_bound = 10**(math.floor(math.log10(min_res) / 5) * 5) # 5 is the step size

    time_lower_bound = 10**(math.floor(math.log10(min_time) / 5) * 5) # 5 is the step size
    time_upper_bound = 10**(math.ceil(math.log10(max_time) / 5) * 5) # 5 is the step size

    iter_ax.set(
        ylim=[lower_bound, 100]
    )
    time_ax.set(
        ylim=[time_lower_bound, time_upper_bound]
    )

    handles, labels = time_ax.get_legend_handles_labels()
    unique = [(h, l) for i, (h, l) in enumerate(zip(handles, labels)) if l not in labels[:i]]

    # iter_ax.legend(loc='lower left', markerscale=4)
    if not args.no_labels:
        time_ax.legend(*zip(*unique), bbox_to_anchor=(1,1), loc='upper left', markerscale=4)

    fig.savefig(f'{args.output_dir}/{solver}.svg')
    fig.savefig(f'{args.output_dir}/{solver}.png')
