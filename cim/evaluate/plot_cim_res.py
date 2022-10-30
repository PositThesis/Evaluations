#!/usr/bin/env python

import os
import matplotlib.pyplot as plt
import json
import argparse
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument('-i', dest='input_folder', required='True', action='store')
arguments = parser.parse_args()

types = ['Float', 'Double', 'LongDouble', 'Posit16', 'Posit163', 'Posit164', 'Posit165', 'Posit32', 'Posit323', 'Posit323', 'Posit324', 'Posit325', 'Posit64', 'Posit643', 'Posit644', 'Posit645']

types2 = [f'{ty}_no_fdp' for ty in types if 'Posit' in ty]

def read_points(num):
    folder = f'{arguments.input_folder}/{num}'
    if not os.path.exists(folder):
        return {}
    data = {ty: json.load(open(f'{folder}/{ty}_residuals.json')) for ty in types+types2 if os.path.exists(f'{folder}/{ty}_residuals.json')}
    return data

def list_of_points():
    nums = [int(num) for num in os.listdir(arguments.input_folder)]
    nums.sort()
    return nums

def xy_from_data(data, ty):
    if ty not in data[list(data.keys())[0]]: return { 'x': [], 'y_max': [], 'y_min': [], 'microseconds': [] }
    return {
        'x': [num for num in data.keys()],
        'y_max': [data[num][ty]['max'] for num in data.keys()],
        'y_min': [data[num][ty]['min'] for num in data.keys()],
        'time': [data[num][ty]['microseconds'] for num in data.keys()]
    }

averages = {}

points = list_of_points()
data = { point: read_points(point) for point in points if read_points(point) != {} }
print(points)
print(list(data[800]))

for ty in types+types2:
    xy = xy_from_data(data, ty)
    pd.DataFrame(xy).to_csv(f'cim_residuals_{ty}.csv')
    averages[ty] = pd.DataFrame(xy).loc[:, 'y_max'].mean()

pd.Series(averages, name='mean').to_frame().reset_index().rename(columns={'index': 'type'}).to_csv('means.csv')


        #plt.plot(
            #xy['x'],
            #xy['y_min'],
            #label = f'{ty} min',
            #linestyle = '-',
            #marker = 'x'
        #)
        #plt.plot(
            #xy['x'],
            #xy['y_max'],
            #label = f'{ty} max',
            #linestyle = '-',
            #marker = '.'
        #)
    #plt.yscale('log')
    #plt.xlabel('Number of contour samples')
    #plt.ylabel('Residual')
    #plt.legend()
    #plt.savefig('all_residuals.svg')
    #plt.close()

    #for ty in types:
        #xy = xy_from_data(data, ty)
        #plt.plot(
            #xy['x'],
            #xy['y_max'],
            #label = f'{ty}',
            #linestyle = '-'
        #)
    #plt.xlabel('Number of contour samples')
    #plt.ylabel('Largest residual')
    #plt.yscale('log')
    #plt.legend()
    #plt.savefig('max_residuals.svg')
    #plt.close()
