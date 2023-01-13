#!/usr/bin/env python3

import sys
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
sns.set_style("whitegrid")

dftx = pd.read_csv("TempCSVfiles/TXv1.csv")
dfrx = pd.read_csv("TempCSVfiles/RXv1.csv")

print(dftx['vlan.id'].value_counts())
print(dfrx['vlan.id'].value_counts())

Time_Data = pd.merge(dftx, dfrx[['ip.src', 'ip.id', 'vlan.id', 'frame.time_epoch']], on=['ip.src', 'ip.id', 'vlan.id'], how='left')
Time_Data['delay(s)'] = Time_Data.apply(lambda row: row["frame.time_epoch_y"] - row["frame.time_epoch_x"], axis=1)
Time_Data["Packet Number"] = Time_Data.index
# Time_Data["Packet Number"] = Time_Data["ip.id"].apply(lambda u: int(u, 0))

# rte = dftx.groupby(['ip.id', 'udp.dstport']).size().reset_index().rename(columns={0: 'count'})
# print(rte[rte['count'] != 1])
# print(rte['count'].value_counts())
# # and a[i].dport == 4001:

# sns.scatterplot(x="Packet Number", y="delay(s)", data=Time_Data)
# Time_Data.loc[Time_Data["ip.id"] == 15645]
# sns.lineplot(x='Packet Number', y='delay(s)', hue='udp.dstport', data=Time_Data)
# sns.stripplot(x='vlan.id', y='delay(s)', data=Time_Data)
fig = sns.relplot(x="Packet Number",y="delay(s)", hue='vlan.id', kind='scatter', data=Time_Data)
plt.savefig('NoSched_v1.eps', dpi=600)
plt.show()
