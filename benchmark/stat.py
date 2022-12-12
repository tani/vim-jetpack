#!/usr/bin/env python3
import sys
import re
import pandas as pd
import matplotlib.pyplot as plt

targets = ['jetpack', 'plug']
data = []

for target in targets:
    ts = []
    with open(target+'.log', 'r') as f:
        line = f.readline()
        while line:
            if re.match(r'.*neomake/log\.vim', line):
                ts.append(float(re.sub(r'\s.*', '', line)))
            line = f.readline()
    data.append(ts)

# transpose data
data = list(map(list, zip(*data)))
df = pd.DataFrame(data=data, columns=targets)

with plt.xkcd():
    plt.figure()
    df.plot.box()
    plt.savefig('benchmark.png')
    plt.close('all')

print(df.describe())
