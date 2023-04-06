#!/bin/bash

# Author: Joydeep Pal
# Date: Oct 2022
# Description: Broadly, it transmits heavy traffic (using iperf)
# to the destination end-host via the local switch.
# Use relevant python script to analyze the performance.

# It uses ssh to run remote commands and
# you should have set up ssh and configured passwordless ssh.

# Script parameters:
BandwidthTest=100M
PacketSize=1000
Duration=5
DurationCapture=$(($Duration+5))
ParallelStreams=1

RemoteIP=10.114.64.107

LocalCaptureEthernetInterface=enp3s0
LocalCaptureInterfaceIP=10.114.64.70
RemoteCaptureEthernetInterface=enp7s0
RemoteCaptureInterfaceIP=10.114.64.107
Port=4000

TXfile=/tmp/tx_trial.pcap
RXfile=/tmp/rx_trial.pcap
RemoteCapture=$TXfile

# System Design:
# Using regular Ethernet port (1GbE) of the hosts because of connection to local switch
# (PC#1) MultiNIC_TX_port --> LocalSwitch_P0 --> LocalSwitch_P1 --> (PC #2) MultiNIC_RX_port

echo 'Step 1: Start packet rx (iperf server) on local node'
iperf -s -u -p $Port &

echo 'Step 2: Start packet capture on tx and rx nodes'
tshark -i $LocalCaptureEthernetInterface -a duration:$DurationCapture -w $RXfile &
ssh zenlab@$RemoteIP "tshark -i $RemoteCaptureEthernetInterface -a duration:$DurationCapture -w $RemoteCapture" &
sleep 5

echo 'Step 3: Start packet tx (iperf client) on remote node'
ssh zenlab@$RemoteIP " \
iperf -u -c $LocalCaptureInterfaceIP -t $Duration -p $Port -b $BandwidthTest -P $ParallelStreams && #>/dev/null
#iperf3 -u -c $LocalCaptureInterfaceIP -t $Duration -p $Port -b $BandwidthTest -l $PacketSize &&
ls /tmp/ | grep tx \
"

echo 'Step 4: Transfer Tx capture file from remote to local system for analysis'
sleep 8
scp -C zenlab@$RemoteIP:$RemoteCapture $TXfile

echo 'Step 5: Convert pcap to csv'
args="-T fields -E header=y -E separator=, \
-e ip.id -e ip.src -e ip.dst -e udp.srcport -e udp.dstport \
-e frame.time_epoch -e udp.length.bad -e udp.length -e data.len"
eval tshark -r $TXfile $args -Y 'udp.dstport==4000' > ../TempCSVfiles/TXv1.csv &
eval tshark -r $RXfile $args -Y 'udp.dstport==4000' > ../TempCSVfiles/RXv1.csv

echo 'Step 6: Process using python script'

killall iperf
echo 'Done !!'
