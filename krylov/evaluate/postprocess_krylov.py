#!/usr/bin/env nix-shell
#!nix-shell -i python -p "python3.withPackages(p: with p; [pandas matplotlib])"

import matplotlib.pyplot as plt
import pandas as pd
import os
import sys
import math

import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-i', dest='input', action='store', required = True)
parser.add_argument('-o', dest='output_dir', action='store', required = True)
parser.add_argument('-max_iter', dest='max_iter', type=int, action='store', required = True)
parser.add_argument('-tol', dest='tol', type=float, action='store', required = True)
args = parser.parse_args()

figures = {
    'GMRES': plt.subplots(1, 2, dpi=600, figsize=(14, 5)),
    'QMR': plt.subplots(1, 2, dpi=600, figsize=(14, 5)),
    'QMRWLA': plt.subplots(1, 2, dpi=600, figsize=(14, 5)),
}
start_idx = 0

for s_idx, solver in enumerate(['GMRES', 'QMR', 'QMRWLA']):
    fig, axes = figures[solver]
    iter_ax = axes[0]
    iter_ax.set(
        title=f'{solver}',
        xlabel='Iterations',
        ylabel='Relative residual',
        yscale="log",
        xlim=[1, args.max_iter],
        xscale="linear"
    )
    time_ax = axes[1]
    time_ax.set(
        xlabel='Runtime in s',
        ylabel='Relative residual',
        yscale="log",
        xscale="log"
    )
    min_res = 1
    for color, num in [('tab:blue', 'Float'), ('tab:orange', 'Double'), ('tab:green', 'LongDouble'), ('tab:red', 'Posit16'), ('tab:purple', 'Posit32'), ('tab:brown', 'Posit64')]:
        filename = f'{args.input}/{solver}_{num}.csv'
        # print(f'processing {filename}')
        if os.path.exists(filename):
            data = pd.read_csv(filename)

            # some sanity checks: remove rows if their iteration is larger than the row that follows. do so by checking for negative diffs
            diffs = data.iloc[:, 1].diff().shift(-1)
            keep = (diffs >= 0) | diffs.isnull()
            data = data.loc[keep, :].reset_index(drop=True)
            # print(data.head(5))

            # do the same again, to remove repeated iterations (but use strict > this time)
            diffs = data.iloc[:, 1].diff().shift(-1)
            keep = (diffs > 0) | diffs.isnull()
            data = data.loc[keep, :].reset_index(drop=True)
            # print(data.head(5))

            # reset time axis
            data.iloc[:, 0] -= data.iloc[0, 0]
            data.iloc[0, 2] = 1

            #remove unreasonably low initial residuals
            for idx in range(5):
                if idx < data.shape[0]:
                    if data.iloc[idx, 2] < 1e-3:
                        data.iloc[idx, 2] = float('nan')

            # remove negative residuals. these are inserted when we skip certain iterations
            data = data.loc[data.loc[:, 'residual'] >= 0, :]

            print(f'plotting {num}, {solver}')
            alpha = 0.5 if solver == 'GMRES' else 1
            iter_ax.plot(data.iloc[start_idx:, 1], data.iloc[start_idx:, 2], 1.0, label = "", color=color, linestyle='-', alpha=alpha)
            time_ax.plot(data.iloc[start_idx:, 0]/1e6, data.iloc[start_idx:, 2], 1.0, label = num, color=color, linestyle='-', alpha=alpha)

            min_res = max(min(min_res, data.iloc[start_idx:, 2].min()), args.tol)
        else:
            print(f'{filename} not found')

    lower_bound = 10**(math.floor(math.log10(min_res) / 5) * 5) # 5 is the step size

    iter_ax.set(
        ylim=[lower_bound, 10]
    )
    time_ax.set(
        ylim=[lower_bound, 10]
    )

    handles, labels = time_ax.get_legend_handles_labels()
    unique = [(h, l) for i, (h, l) in enumerate(zip(handles, labels)) if l not in labels[:i]]

    # iter_ax.legend(loc='lower left', markerscale=4)
    time_ax.legend(*zip(*unique), bbox_to_anchor=(1,1), loc='upper left', markerscale=4)

    fig.savefig(f'{args.output_dir}/{solver}.svg')
    fig.savefig(f'{args.output_dir}/{solver}.png')
