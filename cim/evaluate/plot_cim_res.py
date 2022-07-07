#!/usr/bin/env python

import os
import matplotlib.pyplot as plt
import json
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-i', dest='input_folder', required='True', action='store')
arguments = parser.parse_args()

types = ['Float', 'Double', 'LongDouble', 'Posit162', 'Posit322', 'Posit644']

def read_points(num):
    folder = f'{arguments.input_folder}/{num}'
    if not os.path.exists(folder):
        return {}
    data = {ty: json.load(open(f'{folder}/{ty}_residuals.json')) for ty in types if os.path.exists(f'{folder}/{ty}_residuals.json')}
    return data

def list_of_points():
    nums = [int(num) for num in os.listdir(arguments.input_folder)]
    nums.sort()
    return nums

def xy_from_data(data, ty):
    if ty not in data[list(data.keys())[0]]: return { 'x': [], 'y_max': [], 'y_min': [] }
    return {
        'x': [num for num in data.keys()],
        'y_max': [data[num][ty]['max'] for num in data.keys()],
        'y_min': [data[num][ty]['min'] for num in data.keys()],
    }

if __name__ == '__main__':
    points = list_of_points()
    data = { point: read_points(point) for point in points if read_points(point) != {} }

    for ty in types:
        xy = xy_from_data(data, ty)
        plt.plot(
            xy['x'],
            xy['y_min'],
            label = f'{ty} min',
            linestyle = '-',
            marker = 'x'
        )
        plt.plot(
            xy['x'],
            xy['y_max'],
            label = f'{ty} max',
            linestyle = '-',
            marker = '.'
        )
    plt.yscale('log')
    plt.legend()
    plt.savefig('cim_residuals.svg')