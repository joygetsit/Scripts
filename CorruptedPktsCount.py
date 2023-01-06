#!/usr/bin/env python3

import sys
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
sns.set_style("whitegrid")
# numpy.set_printoptions(threshold=sys.maxsize)
# dftx = pd.read_csv("../../TXport0.csv")
dftx = pd.read_csv("TempCSVfiles/TXv1.csv")
dfrx = pd.read_csv("TempCSVfiles/RXv1.csv")

# Counts
TX_Pkts = dftx.shape[0]
RX_Pkts = dfrx.shape[0]
DiffTxRx = TX_Pkts - RX_Pkts
DiffTxRxPercent = (TX_Pkts - RX_Pkts)*100/TX_Pkts
print("Tx:", TX_Pkts, "| Rx:", RX_Pkts)
print("Lost = Tx-Rx: %d, %.2f" % (DiffTxRx, DiffTxRxPercent))

ip_src = dftx['ip.src'].mode()[0]
ip_dst = dftx['ip.dst'].mode()[0]
udp_src = dftx['udp.srcport'].mode()[0]
udp_dst = dftx['udp.dstport'].mode()[0]
udp_pkt_length = dftx['udp.length'].mode()[0]
data_len=dftx['data.len'].mode()[0]
print(ip_src, ip_dst, udp_src, udp_dst, udp_pkt_length, data_len)
print("Count IPsrc = ", np.where(dfrx['ip.src'] == ip_src)[0].size)
print("Count IPdst = ", np.where(dfrx['ip.dst'] == ip_dst)[0].size)
print("Count BadLength = ", np.where((dfrx['udp.length'] != udp_pkt_length) & (dfrx['udp.length.bad'] == 1))[0].size)
print("Count Udp_src/dst = ", np.where((dfrx['udp.srcport'] != udp_src) | (dfrx['udp.dstport'] != udp_dst))[0].size)
Corrupted_Packets = np.where((dfrx['ip.src'] == ip_src) &
        (dfrx['ip.dst'] == ip_dst) &
        (dfrx['udp.srcport'] == udp_src) & (dfrx['udp.dstport'] == udp_dst) &
        (dfrx['udp.length'] == data_len+8) & (dfrx['udp.length.bad'] != 1))[0].size
print("CorruptedPacketsRx : ", Corrupted_Packets)
print("Corrupt_wrt_Rx : %.2f" % (Corrupted_Packets*100/RX_Pkts))
print("Corrupt_wrt_Tx : %.2f" % (Corrupted_Packets*100/TX_Pkts))

# Below commented code is to create the csv file, has to be run just once when no file exists
# FrameData = pd.DataFrame([['PacketSize',
#                            'Bandwidth',
#                            'Duration',
#                            'TX_Pkts',
#                            'RX_Pkts',
#                            'DiffTxRx',
#                            'DiffTxRxPercent',
#                            'Corrupted_Packets',
#                            'Corrupted_Packets/RX_Pkts%',
#                            'Corrupted_Packets/TX_Pkts%',
#                            'Date']])
# FrameData.to_csv("TempCSVfiles/Counts.csv", mode='w', header=False, index=False)

# Writes data to csv file
FrameData = [sys.argv[1], sys.argv[2], sys.argv[3],
             TX_Pkts, RX_Pkts, DiffTxRx, round(DiffTxRxPercent,2),
             Corrupted_Packets, round((Corrupted_Packets*100/RX_Pkts),2),
             round((Corrupted_Packets*100/TX_Pkts),2), pd.Timestamp.today()]
FrameDf = pd.DataFrame([FrameData])
FrameDf.to_csv("TempCSVfiles/Counts.csv", mode='a', header=False, index=False)
