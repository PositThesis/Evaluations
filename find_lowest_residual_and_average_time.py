#!/usr/bin/env nix-shell
#!nix-shell -p "python3.withPackages(p: with p; [pandas])" -i python

import pandas as pd
import re
path = 'eval_221025_2/krylov/sherman/fdp/data/sherman5/'

min_res = {}
average_time = {}

labels = {
    'Float': 'float',
    'Double': 'double',
    'LongDouble': 'long double',
    'Posit16': 'posit16',
    'Posit32': 'posit32',
    'Posit64': 'posit64',
    'Posit16_no_fdp': 'posit16_no_fdp',
    'Posit32_no_fdp': 'posit32_no_fdp',
    'Posit64_no_fdp': 'posit64_no_fdp',
}

for algorithm in ['GMRES', 'QMR', 'QMRWLA']:
    min_res[algorithm] = {}
    average_time[algorithm] = {}
    for ty in ['Float', 'Double', 'LongDouble', 'Posit16', 'Posit32', 'Posit64', 'Posit16_no_fdp', 'Posit32_no_fdp', 'Posit64_no_fdp']:
        if 'no_fdp' in ty:
            path_ = path.replace('fdp', 'no_fdp')
            ty_ = ty.replace('_no_fdp', '')
            suffix = '_no_fdp'
        else:
            path_ = path
            ty_ = ty
            suffix = ''
        fp = f'{path_}{algorithm}/{ty_}_{algorithm}{suffix}.csv'
        df = pd.read_csv(fp)
        df = df.loc[df.loc[:, 'residual'] >= 0, :]

        min_res[algorithm][ty] = df.loc[:, 'residual'].min()
        last_row = df.iloc[-1, :]
        average_time[algorithm][ty] = last_row['time [μs]']/last_row['iteration']/1e3

def exponent_positive(match):
    if str(match.group(1)) == '00':
        return ''
    if str(match.group(1)).startswith('0'):
        return '\\cdot 10^{'+match.group(1)[1:]+'}'

    return '\\cdot 10^{'+match.group(1) +'}'

def exponent_negative(match):
    if str(match.group(1)).startswith('0'):
        return '\\cdot 10^{-'+match.group(1)[1:]+'}'

    return '\\cdot 10^{-'+match.group(1) +'}'


for algorithm in ['GMRES', 'QMR', 'QMRWLA']:
    print(algorithm)
    print('''
    \\begin{tabular}{|l|p{3cm}|p{3cm}|p{3cm}|p{3cm}|}
        \\hline
        Type & Lowest Relative Residual       & Lowest Relative Residual Normalized to double & Average Time per Iteration in ms & Average Time per Iteration Normalized to double      \\\\\\hline\\hline
    ''')
    for ty in ['Float', 'Double', 'LongDouble', 'Posit16', 'Posit32', 'Posit64', 'Posit16_no_fdp', 'Posit32_no_fdp', 'Posit64_no_fdp']:
        res_normalized = '{:.2e}'.format(min_res[algorithm][ty]/min_res[algorithm]['Double'])
        time_normalized = '{:.2e}'.format(average_time[algorithm][ty]/average_time[algorithm]['Double'])
        row = f'{labels[ty]} & ${min_res[algorithm][ty]:.2e}$ & ${res_normalized}$ & ${average_time[algorithm][ty]:.2e}$ & ${time_normalized}$ \\\\\\hline'
        row = re.sub('e\+(\d+)', exponent_positive, row)
        row = re.sub('e-(\d+)', exponent_negative, row)
        print(row)
        # print(f'{algorithm} {ty}:')
        #print(f'\tmin_res: {min_res[algorithm][ty]:.2e}')
        #print('\tmin_res_normalized: {:.2e}'.format(min_res[algorithm][ty]/min_res[algorithm]['Double']))
        #print(f'\tavg_time: {average_time[algorithm][ty]:.2e}')
        #print('\tavg_time_normalized: {:.2e}'.format(average_time[algorithm][ty]/average_time[algorithm]['Double']))
    print('\\end{tabular}')