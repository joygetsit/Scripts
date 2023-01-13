#!/usr/bin/env python3

import sys
import pandas as pd
import numpy as np
import time
import matplotlib.pyplot as plt
import seaborn as sns
sns.set_style("whitegrid")

plt.rcParams['savefig.format']='pdf'
# numpy.set_printoptions(threshold=sys.maxsize)
dftx = pd.read_csv("TempCSVfiles/TXv1.csv")
dfrx = pd.read_csv("TempCSVfiles/RXv1.csv")

print(dftx['udp.srcport'].value_counts())
print(dftx['udp.dstport'].value_counts())
print(dfrx['udp.srcport'].value_counts())

# Field which needs to be compared
Field1 = np.where(dftx['ip.id'] != dfrx['ip.id'])
# Field1 = np.where(dftx['vlan.id'] != dfrx['vlan.id'])
FieldList = list(Field1[0])
print("Length FieldList : ", len(FieldList)) #, FieldList)
plt.plot(FieldList)
name = f'TempFigures/Fig1_{round(time.time())}'
plt.savefig(name)
# plt.show(block=False)
