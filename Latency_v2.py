#!/usr/bin/env python3

import sys
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
sns.set_style("whitegrid")
# import os
# os.chdir("Codes")

dftx = pd.read_csv("../TXv1.csv")
dfrx = pd.read_csv("../RXv1.csv")
# dftx = pd.read_csv("TXv1.csv")
# dfrx = pd.read_csv("TX_Netro_p0.csv")
print(dftx['udp.dstport'].value_counts())
print(dfrx['udp.dstport'].value_counts())

Time_Data = pd.merge(dftx, dfrx[['ip.id', 'udp.dstport', 'frame.time_epoch']], on=['ip.id', 'udp.dstport'], how='left')
# Time_Data = dftx.merge(dfrx, left_on='ip.id', right_on='ip.id')
Time_Data['delay(s)'] = Time_Data.apply(lambda row: row["frame.time_epoch_y"] - row["frame.time_epoch_x"], axis=1)
Time_Data["Packet Number"] = Time_Data["ip.id"].apply(lambda u: int(u, 0))

# rte = dftx.groupby(['ip.id', 'udp.dstport']).size().reset_index().rename(columns={0: 'count'})
# print(rte[rte['count'] != 1])
# print(rte['count'].value_counts())
# # and a[i].dport == 4001:

# sns.scatterplot(x="Packet Number", y="delay(s)", data=Time_Data)
# Time_Data.loc[Time_Data["ip.id"] == 15645]
# sns.lineplot(x='Packet Number', y='delay(s)', hue='udp.dstport', data=Time_Data)
sns.stripplot(x='udp.dstport', y='delay(s)', data=Time_Data)
plt.show()
