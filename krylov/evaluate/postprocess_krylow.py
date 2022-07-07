#!/usr/bin/env nix-shell
#!nix-shell -i python -p "python3.withPackages(p: with p; [pandas matplotlib])"

import matplotlib.pyplot as plt
import pandas as pd
import os

import sys

if len(sys.argv) != 3 and len(sys.argv) != 2:
    print('use "./postprocess <folder> [<max_iter>]"')
    exit(-1)

folder = sys.argv[1]
max_iter = int(sys.argv[2]) if len(sys.argv) > 2 else -1

figures = {
    'GMRES': plt.subplots(1, 2, dpi=600, figsize=(14, 5)),
    'QMR': plt.subplots(1, 2, dpi=600, figsize=(14, 5)),
    'QMRWLA': plt.subplots(1, 2, dpi=600, figsize=(14, 5)),
}
start_idx = 0

min_res = 1e-80

for s_idx, solver in enumerate(['GMRES', 'QMR', 'QMRWLA']):
    fig, axes = figures[solver]
    if solver == 'GMRES':
        min_res = 1e-25
    if solver == 'QMR':
        min_res = 1e-25
    if solver == 'QMRWLA':
        min_res = 1e-25
    iter_ax = axes[0, s_idx]
    iter_ax.set(
        title=f'{solver}',
        xlabel='Iterations',
        ylabel='Relative residual',
        ylim=[min_res, 10],
        yscale="log",
        xlim=[1, max_iter if max_iter > 0 else 6624],
        xscale="linear"
    )
    time_ax = axes[1, s_idx]
    time_ax.set(
        xlabel='Runtime in s',
        ylabel='Relative residual',
        ylim=[min_res, 10],
        yscale="log",
        xscale="log"
    )
    for color, num in [('tab:blue', 'Float'), ('tab:orange', 'Double'), ('tab:green', 'LongDouble'), ('tab:red', 'Posit162'), ('tab:purple', 'Posit322'), ('tab:brown', 'Posit644')]:
        filename = f'{folder}/{solver}_{num}.csv'
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

            iter_ax.scatter(data.iloc[start_idx:, 1], data.iloc[start_idx:, 2], 1.0, label=num, color=color)
            time_ax.scatter(data.iloc[start_idx:, 0]/1e6, data.iloc[start_idx:, 2], 1.0, label=num, color=color)

    #if max_iter > 0:
    #    iter_ax.axvline(x=max_iter, label='Max Iterations')

    iter_ax.legend(loc='lower left', markerscale=4)
    time_ax.legend(loc='lower left', markerscale=4)

    fig.savefig(f'{folder}/{solver}.svg')
