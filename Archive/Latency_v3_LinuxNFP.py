#!./venv/bin/python3

import sys
import datetime
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

sns.set_style("white")
sns.set(font_scale=1.5)

BinSize = 20
print(datetime.datetime.now())
FileDate = datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S")
BW = 'Low'  # 'High'  # 'Low'
# import os
# os.chdir('Scripts')

if len(sys.argv) > 1:
    ST = sys.argv[1]
    BE = sys.argv[2]
    Duration = sys.argv[3]
else:
    ST = 'Trial'
    BE = 'Trial'
    Duration = 'Trial'
FigureName = '../TempFigures/' + BW + 'LinkBW_' + 'S_' + ST + \
             '_B_' + BE + '_Dur_' + Duration + 's_' + FileDate + '.png'
FigureNameLostPercentage = '../TempFigures/LostPercent_' + ST + \
                           BE + 'Dur' + Duration + FileDate + '.png'
FigureNameLostCount = '../TempFigures/LostCount_' + \
                      ST + BE + 'Dur' + Duration + FileDate + '.png'
csvFilename = '../TempCSVfiles/MergedTxRx_' + ST + \
              BE + 'Dur' + Duration + FileDate + '.csv'

dftx = pd.read_csv("../../TempCSVfiles/TXv1.csv")
dfrx = pd.read_csv("../../TempCSVfiles/RXv1.csv")

dftx.rename(columns={"udp.dstport": "Flows"}, inplace=True)
dfrx.rename(columns={"udp.dstport": "Flows"}, inplace=True)

print('Tx Count = ' + str(dftx['Flows'].count()))
print('Rx Count = ' + str(dfrx['Flows'].count()))
dftx = dftx.loc[dftx['Flows'].isin([3001, 3002])]
dfrx = dfrx.loc[dfrx['Flows'].isin([3001, 3002])]
print(dftx['Flows'].value_counts(dropna=False))
print(dfrx['Flows'].value_counts(dropna=False))
# dftx['Flows'].value_counts()[3.0]

dftx = dftx[~dftx['Flows'].isnull()]
dfrx = dfrx[~dfrx['Flows'].isnull()]

Time_Data = pd.merge(dftx, dfrx[['ip.src', 'ip.id', 'Flows', 'frame.time_epoch']],
                     on=['ip.src', 'ip.id', 'Flows'], how='left')

Time_Data['Latency (ms)'] = Time_Data.apply(lambda row: (row["frame.time_epoch_y"] - row["frame.time_epoch_x"])*1000, axis=1)

Time_Data['Flows'] = Time_Data['Flows'].replace([3001], 'ST')
Time_Data['Flows'] = Time_Data['Flows'].replace([3002], 'BE')

# Time_Data['frame.time_epoch_x'] = pd.to_datetime(Time_Data['frame.time_epoch_x'], unit='s')
# Time_Data['frame.time_epoch_y'] = pd.to_datetime(Time_Data['frame.time_epoch_y'], unit='s')
# Time_Data['Latency (ms)'] = pd.to_datetime(Time_Data['Latency (ms)'], unit='s')

# Time_Data['Latency1 (ms)'] = Time_Data.apply(lambda row: (row["frame.time_epoch_y"] - row["frame.time_epoch_x"])*1000, axis=1)
# Time_Data = Time_Data.astype({'Latency1 (ms)': 'float'})

Time_Data = Time_Data.iloc[40:]

Time_Data["Packet Number"] = Time_Data.index
# Time_Data["Packet Number"] = Time_Data["ip.id"].apply(lambda u: int(u, 0))
print(Time_Data.groupby(['Flows']).min()['Latency (ms)'])
print(Time_Data.groupby(['Flows']).max()['Latency (ms)'])

TxPacketCount = Time_Data['Flows'].value_counts().to_frame()
RxPacketCount = Time_Data[Time_Data["frame.time_epoch_y"].isnull()]['Flows'].value_counts().to_frame()
# A = (TxPacketCount['Flows'][2] - RxPacketCount['Flows'][2]) * 100/ TxPacketCount['Flows'][2]
# B = (TxPacketCount['Flows'][3] - RxPacketCount['Flows'][3]) * 100 / TxPacketCount['Flows'][3]

if 2 in RxPacketCount.index:
    A = RxPacketCount['Flows'][2] * 100 / TxPacketCount['Flows'][2]
    print(f"VLAN 2 Loss = {A:.2f}")
else:
    print(f'VLAN 2 Loss = 0')
if 3 in RxPacketCount.index:
    B = RxPacketCount['Flows'][3] * 100 / TxPacketCount['Flows'][3]
    print(f"VLAN 3 Loss = {B:.2f}")
else:
    print(f'VLAN 3 Loss = 0')
# rte = dftx.groupby(['ip.id', 'Flows']).size().reset_index().rename(columns={0: 'count'})


# sns.stripplot(x='Flows', y='delay(s)', data=Time_Data)
BinsNo = len(Time_Data)/BinSize
Time_Data['Time Axis'] = Time_Data['Packet Number']/BinsNo
Time_Data = Time_Data.astype({'Time Axis': 'int'})
# Time_Data[Time_Data['Time Axis'] == 0]['frame.time_epoch_x'].mean()

# for i in Time_Data['Time Axis'].unique():
#     Time_Data[Time_Data['Time Axis'] == i]['frame.time_epoch_x'].mean()
# ['Time_Axis']

# Plot event of lost packets (in terms of count) vs time
df3 = Time_Data[Time_Data["frame.time_epoch_y"].isnull()][[
    "frame.time_epoch_x", "Packet Number", "Flows", "Time Axis"]]
PacketsBin = Time_Data[['Time Axis', 'Flows']].value_counts().reset_index(name='count')
LostPacketsBin = df3[['Time Axis', 'Flows']].value_counts().reset_index(name='count2')
LostPacketsBin2 = pd.merge(LostPacketsBin, PacketsBin, on=['Time Axis', 'Flows'], how='left')
LostPacketsBin2['Loss %age'] = LostPacketsBin2['count2'] * 100 / LostPacketsBin2['count']


# # Plot on separate axis
# Time_DataVlan2 = Time_Data[Time_Data['Flows']==2]
# Time_DataVlan3 = Time_Data[Time_Data['Flows']==3]
# fig,ax=plt.subplots()
# ax1=ax.twinx()
# sns.catplot(data=Time_DataVlan2, x='Time Axis', y="Latency (ms)", kind='box', showfliers=False)
# plt.title("Scheduled Traffic - (VLAN 2)")
# sns.catplot(data=Time_DataVlan3, x='Time Axis', y="Latency (ms)", kind='box', showfliers=False)
# plt.title("BE Traffic - (VLAN 3)")


# # Plot catplot(boxplot) without outliers
# flierprops = dict(marker='o', markersize=1)
# sns.catplot(data=Time_Data, x='Time Axis', y="Latency (ms)", hue="Flows", kind='box', showfliers=False)
# plt.title('Tx Count = ' + str(dftx['Flows'].count()) + ' | Rx Count = ' + str(dfrx['Flows'].count()))
# Figure = plt.gcf()
# # sns.relplot(x="Packet Number", y="Latency (ms)", hue='Flows', kind='scatter', data=Time_Data)
# Figure.set_size_inches(16, 9)
# plt.savefig(FigureName, dpi=300)
# sns.catplot(data=Time_Data, x='Time Axis', y="Latency (ms)", hue="Flows", kind='box', flierprops=flierprops)
# plt.grid()

# Plot catplot(boxplot) without outliers
flierprops = dict(marker='o', markersize=1)
sns.set_style("white")
fig, axes = plt.subplots(2, 1, sharex='col', tight_layout=True)
fig.suptitle('Latency vs Time - for Scheduled Traffic and Best Effort flows - [Scheduled Traffic (ST)]')
sns.boxplot(ax=axes[0], data=Time_Data.loc[Time_Data["Flows"] == 'ST'], x='Time Axis', y="Latency (ms)", showfliers=True)
# plt.title('Scheduled Traffic (ST)')
sns.boxplot(ax=axes[1], data=Time_Data.loc[Time_Data["Flows"] == 'BE'], x='Time Axis', y="Latency (ms)", showfliers=True)
sns.despine()
plt.title('[Best Effort Traffic (BE)]')
# plt.title('Tx Count = ' + str(dftx['Flows'].count()) + ' | Rx Count = ' + str(dfrx['Flows'].count()))
Figure = plt.gcf()
# sns.relplot(x="Packet Number", y="Latency (ms)", hue='Flows', kind='scatter', data=Time_Data)
Figure.set_size_inches(16, 9)
plt.savefig(FigureName, dpi=300)

sns.catplot(data=Time_Data, x='Time Axis', y="Latency (ms)", hue="Flows", kind='box', flierprops=flierprops)
sns.despine()
Figure = plt.gcf()
# sns.relplot(x="Packet Number", y="Latency (ms)", hue='Flows', kind='scatter', data=Time_Data)
Figure.set_size_inches(17, 9)
plt.grid()

# if df3.shape[0] > 0:
#     sns.catplot(data=df3, x='Time Axis', kind="count", hue="Flows")
#     plt.savefig(FigureNameLostCount, dpi=300)
#     sns.relplot(data=LostPacketsBin2, x='Time Axis', y='Loss %age', hue='Flows')
#     plt.savefig(FigureNameLostPercentage, dpi=300)

# sns.relplot(data=popot, x='frame.time_epoch_x', y="Packet Number", hue='Time Axis
# MissingPkts = Time_Data["frame.time_epoch_y"].isnull().values
# plt.scatter(Time_Data.index, MissingPkts)

Time_Data.to_csv(csvFilename)
plt.show()
