#!/bin/bash

# Author: Joydeep Pal
# Date: Oct 2022
# Description: Broadly, it transmits heavy traffic (using iperf)
# to the destination end-host via the local switch and then analyze the performance.
# It uses ssh to run remote commands and
# you should have set up ssh and configured passwordless ssh.

RemoteIP=10.114.64.107

LocalCaptureEthernetInterface=enp3s0
LocalCaptureInterfaceIP=10.114.64.70
RemoteCaptureEthernetInterface=enp7s0
RemoteCaptureInterfaceIP=10.114.64.107
Port=4000

ParallelStreams=1
BandwidthTest=100M
PacketSize=1000
Duration=5
DurationX=15

TXfile=/tmp/tx_trial.pcap
RXfile=/tmp/rx_trial.pcap
RemoteCapture=$TXfile

# System Design:
# Using regular Ethernet port (1GbE) of the hosts because of connection to local switch
# (PC#1) MultiNIC_TX_port --> LocalSwitch_P0 --> LocalSwitch_P1 --> (PC #2) MultiNIC_RX_port

# Iperf gives transport layer bandwidth, so actual bandwidth is a little more
## iperf3 flags
# -b 0 -> Max bandwidth of port (Verified)
# -t for time, -n for bytes, -k for no. of pkts
# -P for number of parallel streams, max bandwidth gets divided between these streams
# -l for length of UDP/TCP payload, related to fragmentation
# Also length increase -> bandwidth utilisation increase

echo 'Step 1: Run Rx (iperf server) on local node'
# Kill iperf server processes at the end of the test
# The argument '-1' with iperf3 closes iperf3 server automatically after 1 session,
# or you can kill iperf3 at the end.
# Better to kill it at the end of the test  to maintain uniformity in your codes
iperf -s -u -p $Port &
#iperf3 -s -p $Port -1 &

echo 'Step 2: Running PacketCapture on Tx and Rx nodes'
tshark -i $LocalCaptureEthernetInterface -a duration:$DurationX -w $RXfile &
#ssh zenlab@$RemoteIP "tshark -i $RemoteCaptureEthernetInterface -a duration:$DurationX -w $RemoteCapture" &
ssh zenlab@$RemoteIP "tshark -i $RemoteCaptureEthernetInterface -a duration:$DurationX -w $RemoteCapture" &
sleep 5

echo 'Step 3: Run Tx (iperf client) on remote node'
ssh zenlab@$RemoteIP " \
iperf -u -c $LocalCaptureInterfaceIP -t $Duration -p $Port -b $BandwidthTest -P $ParallelStreams && #>/dev/null
#iperf3 -u -c $LocalCaptureInterfaceIP -t $Duration -p $Port -b $BandwidthTest -l $PacketSize &&
ls /tmp/ | grep tx \
"

echo 'Step 4: Transfer Tx capture from remote to local system for analysis'
sleep 8
scp -C zenlab@$RemoteIP:$RemoteCapture $TXfile

echo 'Step 5: Convert pcap to csv for automated analysis with python'
args="-T fields -E header=y -E separator=, \
-e ip.id -e ip.src -e ip.dst -e udp.srcport -e udp.dstport \
-e frame.time_epoch -e udp.length.bad -e udp.length -e data.len"
eval tshark -r $TXfile $args -Y 'udp.dstport==4000' > TempCSVfiles/TXv1.csv &
eval tshark -r $RXfile $args -Y 'udp.dstport==4000' > TempCSVfiles/RXv1.csv

echo 'Step 6: Process using python script'
#./OutOfOrderCount.py
#./Latency_v2.py

echo 'Step 7: Open wireshark captures'
# wireshark -r $TXfile &
# wireshark -r $RXfile &

killall iperf
echo "Done !!"

# To segregate ssh output to this xterm rather than in the same terminal,
# start an xterm and execute ssh command
#nohup xterm -hold -e ssh zenlab@10.114.64.107 "" &
