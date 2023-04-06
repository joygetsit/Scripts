#!./venv/bin/python3

import sys
import datetime
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

Plotting = "Subplots" # "Separate"
flierprops = dict(marker='o', markersize=1)  # Define outlier properties of boxplots
# sns.set_style("whitegrid")
# sns.set_context("notebook")
sns.set_theme(style='white', context='notebook', font_scale=0.5, rc={'figure.figsize': (16, 9)})

BinSize = 20
FileDate = datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S")
# BW = 'Low'  # 'High'  # 'Low'

if len(sys.argv) > 1:
    ST = sys.argv[1]
    BE = sys.argv[2]
    Duration = sys.argv[3]
else:
    ST = 'Trial'
    BE = 'Trial'
    Duration = 'Trial'

TestMetadata = pd.DataFrame()

TestMetadata['Bandwidth'] = {'ST': ST, 'BE': BE}
TestMetadata['Timestamp'] = FileDate
TestMetadata['Duration'] = Duration

FigureName = '../TempFigures/' + 'S_' + ST + '_B_' + BE + '_Dur_' + Duration + 's_' + FileDate + '.png'
# FigureNameLostPercentage = '../TempFigures/LostPercent_' + ST + \
#                            BE + 'Dur' + Duration + FileDate + '.png'
# FigureNameLostCount = '../TempFigures/LostCount_' + \
#                       ST + BE + 'Dur' + Duration + FileDate + '.png'
# csvFilename = '../TempCSVfiles/MergedTxRx_' + ST + \
#               BE + 'Dur' + Duration + FileDate + '.csv'

dftx = pd.read_csv("../TempCSVfiles/TXv1.csv")
dfrx = pd.read_csv("../TempCSVfiles/RXv1.csv")

dftx.rename(columns={"vlan.id": "Flows"}, inplace=True)
dfrx.rename(columns={"vlan.id": "Flows"}, inplace=True)
dftx['Flows'].replace({2: 'ST', 3: 'BE'}, inplace=True)
dfrx['Flows'].replace({2: 'ST', 3: 'BE'}, inplace=True)

TxCountTotal = dftx['Flows'].count()
RxCountTotal = dfrx['Flows'].count()
TestMetadata['TxCountOfEachFlow'] = dftx['Flows'].value_counts(dropna=False)
# TxCountOfEachFlow = dftx['Flows'].value_counts(dropna=False)
RxCountOfEachFlow = dfrx['Flows'].fillna('Others').value_counts(dropna=False)
TestMetadata['TxCountOfEachFlow'] = RxCountOfEachFlow
TestMetadata['TxCountTotal'] = TxCountTotal
TestMetadata['RxCountTotal'] = RxCountTotal

# Clean data to keep only our data and remove arp, dns and other irrelevant data
dftx = dftx[~dftx['Flows'].isnull()]
dfrx = dfrx[~dfrx['Flows'].isnull()]

# Merge Tx and Rx data to one dataframe
Time_Data = pd.merge(dftx, dfrx[['ip.src', 'ip.id', 'Flows', 'frame.time_epoch']], on=['ip.src', 'ip.id', 'Flows'], how = 'left')
# This dataframe has all Tx packets and hence can be used to number the packets
Time_Data["Packet Number"] = Time_Data.index
# Time_Data["Packet Number"] = Time_Data["ip.id"].apply(lambda u: int(u, 0))
Time_Data['Latency (ms)'] = (Time_Data["frame.time_epoch_y"] - Time_Data["frame.time_epoch_x"]) * 1000
Time_Data['Missed'] = Time_Data["frame.time_epoch_y"].isnull()
xminPkt = Time_Data['Packet Number'].min()
xmaxPkt = Time_Data['Packet Number'].max()
xminTime = Time_Data['frame.time_epoch_x'].min()
xmaxTime = Time_Data['frame.time_epoch_x'].max()
# CumulativeSumOfLostPackets = Time_Data['Missed'].cumsum()
# CumulativeSumOfReceivedPackets = (~Time_Data['Missed']).cumsum()
# sns.scatterplot(data=Time_Data, x='Packet Number', y=(~Time_Data['Missed']).cumsum())
# sns.scatterplot(data=Time_Data, x='frame.time_epoch_x', y=(~Time_Data['Missed']).cumsum(), hue='Flows')
# Time_Data[Time_Data['Flows']=='BE']['Missed'].cumsum()


''' To remove first few datapoints'''
# Time_Data = Time_Data.iloc[40:]

# Count of relevant data only
TestMetadata['TxPacketCount'] = Time_Data['Flows'].value_counts()
TestMetadata['RxPacketCount'] = Time_Data[~Time_Data["frame.time_epoch_y"].isnull()]['Flows'].value_counts()
TestMetadata['PacketLoss'] = TestMetadata['TxPacketCount'] - TestMetadata['RxPacketCount']
TestMetadata['PacketLoss%'] = (TestMetadata['PacketLoss'] * 100 / TestMetadata['TxPacketCount']).round(2)

# Show min and max latency using graphs
TestMetadata['LatencyMin'] = (Time_Data.groupby(['Flows']).min()['Latency (ms)']).round(2)
TestMetadata['LatencyMax'] = (Time_Data.groupby(['Flows']).max()['Latency (ms)']).round(2)
# df['Count'] = df.groupby(['Medicine'])['Dosage'].transform('count')
# Time_Data.groupby(['Flows'])['Latency (ms)'].describe()
# gfh = Time_Data.groupby(['Time Axis'])
# A = (TxPacketCount['Flows']['ST'] - RxPacketCount['Flows']['ST']) * 100 / TxPacketCount['Flows']['ST']

# BinsNo = len(Time_Data)/BinSize
# Time_Data['Time Axis'] = Time_Data['Packet Number']/BinsNo
Time_Data['Time Axis'] = pd.cut(Time_Data['Packet Number'], bins=BinSize, labels=False)
Time_Data = Time_Data.astype({'Packet Number': 'uint64'})

''' Data divided to bins '''
# Aggregated_Data = Time_Data.groupby(['Time Axis', 'Flows', 'Missed'], as_index=False)
Aggregated_Data = Time_Data.groupby(['Time Axis', 'Flows'], as_index=False)
Aggregated_Data = Time_Data.groupby(['Time Axis', 'Flows'], as_index=False)
AggregatedCount = Aggregated_Data.count()
AggregatedCount['Loss'] = AggregatedCount['Packet Number'] - AggregatedCount['Latency (ms)']
AggregatedCount['Loss %'] = AggregatedCount['Loss'] * 100 / AggregatedCount['Latency (ms)']


''' Lost packets '''
# LostPacketsList = Time_Data[Time_Data['Missed']][[
#     "frame.time_epoch_x", "Packet Number", "Flows", "Time Axis"]]
LostPacketsList = Time_Data[Time_Data['Missed']]

''' Print all information '''
# print('Tx Count = ' + str(TxCountTotal))
# print('TxCountOfEachFlow', TxCountOfEachFlow)
# dftx['Flows'].value_counts()[3.0]

# Printing errrors thgen use below code
# if 'ST' in RxPacketCount.index:
#     A = RxPacketCount['ST'] * 100 / TxPacketCount['ST']
#     print(f"VLAN ST Rx % = {A:.2f}")
# else:
#     print(f'VLAN ST Rx % = 0')
# if 'BE' in RxPacketCount.index:
#     B = RxPacketCount['BE'] * 100 / TxPacketCount['BE']
#     print(f"VLAN BE Rx % = {B:.2f}")
# else:
#     print(f'VLAN BE Rx % = 0')
# rte = dftx.groupby(['ip.id', 'udp.dstport']).size().reset_index().rename(columns={0: 'count'})


if Plotting == "Subplots":
    fig, axes = plt.subplots(3, 4) # , sharex='col', tight_layout=True)
    # fig.suptitle('Latency vs Time - for Scheduled Traffic and Best Effort flows - [Scheduled Traffic (ST)]', y=1)

    ''' Latency - Separate - Aggregate plot '''
    sns.boxplot(ax=axes[0, 0], data=Time_Data.loc[Time_Data["Flows"] == 'ST'], x='Time Axis', y="Latency (ms)", showfliers=False)
    sns.boxplot(ax=axes[0, 1], data=Time_Data.loc[Time_Data["Flows"] == 'BE'], x='Time Axis', y="Latency (ms)", showfliers=False)
    # sns.despine()

    ''' Latency - Separate - Packet plot - CDF(Latency) '''
    sns.ecdfplot(ax=axes[1, 0], data=Time_Data[Time_Data['Flows'] == 'ST'], x="Latency (ms)", stat='count')
    sns.ecdfplot(ax=axes[1, 1], data=Time_Data[Time_Data['Flows'] == 'BE'], x="Latency (ms)", stat='count')

    ''' Latency - One - Aggregate plot '''
    sns.boxplot(ax=axes[2, 0], data=Time_Data, x='Time Axis', y='Latency (ms)', hue='Flows', flierprops=flierprops)

    ''' Latency - One - Packet plot '''
    sns.scatterplot(ax=axes[2, 1], x="Packet Number", y="Latency (ms)", hue='Flows', data=Time_Data)

    ''' Count - One - Aggregate plot - Loss and Loss %age'''
    sns.scatterplot(ax=axes[0, 2], data=AggregatedCount, x='Time Axis', y='Loss', hue='Flows')
    sns.scatterplot(ax=axes[0, 3], data=AggregatedCount, x='Time Axis', y='Loss %', hue='Flows')

    ''' Count - One - Packet plot - Received and Lost packets'''
    # Horizontal packets vs time
    sns.scatterplot(ax=axes[1, 2], data=Time_Data, x='Packet Number', y='Missed', hue='Flows')
    # Diagnol packets vs time
    LostPacketPlot = sns.scatterplot(ax=axes[1, 3], data=LostPacketsList, x='frame.time_epoch_x', y='Packet Number', hue='Time Axis', size='Flows')
    LostPacketPlot.set_ylim(xminPkt, xmaxPkt)
    LostPacketPlot.set_xlim(xminTime, xmaxTime)
    plt.savefig(FigureName)


else:

    ''' Latency - Separate - Aggregate plot '''
    # Plot catplot(boxplot) without outliers for Latency experienced by the ST and BE flows
    LatencyCol = sns.FacetGrid(Time_Data, row='Flows', sharex=True, sharey=False)
    LatencyCol.map(sns.boxplot, 'Time Axis', 'Latency (ms)', showfliers=False)

    ''' Latency - Separate - Packet plot - CDF(Latency) '''
    # plt.figure()
    # LatencyCDF = sns.FacetGrid(Time_Data, col='Flows', sharex=False)
    # LatencyCDF.map(sns.ecdfplot, "Latency (ms)")
    # LatencyCDF.set_ylabels("CDF/Proportion")
    LatencyCountCDF = sns.FacetGrid(Time_Data, col='Flows', sharex=False)
    LatencyCountCDF.map(sns.ecdfplot, "Latency (ms)", stat="count")

    ''' Latency - One - Aggregate plot '''
    # sns.catplot(data=Time_Data, x='Time Axis', y="Latency (ms)", hue="Flows", kind='box', flierprops=flierprops) # ,showfliers=False)

    ''' Latency - One - Packet plot '''
    # sns.relplot(x="Packet Number", y="Latency (ms)", hue='Flows', kind='scatter', data=Time_Data)
    # sns.stripplot(x='Flows', y='Latency (ms)', data=Time_Data)
    # ax1=ax.twinx()
    # Plot of received timestamp for these flows shows clear demarcation
    # sns.scatterplot(data=Time_Data, x='Packet Number', y= 'frame.time_epoch_y', hue='Flows')
    # plt.savefig(FigureName)
    # plt.grid()

    ''' Count - One - Aggregate plot - Received and Lost Packets '''
    plt.figure()
    LostPacketPlotAggregate = sns.countplot(data=Time_Data, x='Time Axis', hue='Flows')

    ''' Count - One - Packet plot - Received and Lost Packets Plot '''
    plt.figure()
    PacketPlot_v0 = sns.scatterplot(data=Time_Data, x='Packet Number', y='Missed', hue='Flows')
    plt.figure()
    LostPacketPlot = sns.scatterplot(data=LostPacketsList, x='frame.time_epoch_x', y='Packet Number', hue='Time Axis',
                                     size='Flows')
    LostPacketPlot.set_ylim(xminPkt, xmaxPkt)
    LostPacketPlot.set_xlim(xminTime, xmaxTime)
    # sns.displot(Time_Data, x='Packet Number', bins=33, hue='Flows', multiple="dodge", discrete=True)
    # plt.savefig(FigureNameLostCount)
    # if LostPacketsList.shape[0] > 0:
    #     sns.countplot(data=LostPacketsList, x='Time Axis', hue="Flows")


plt.show()

''' Write data analysis numbers for this test to csv '''
TestMetadata.to_csv('Experimental.csv', mode='a')

''' To optimize the code '''
# If you want to optimize the python code, you can do the below line and other things
# Such as do strongly-typed code (convert some things to signed int) etc.
# dftx = dftx.astype({'Flows': 'uint8'})
