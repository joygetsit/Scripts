#!/bin/bash

# Author: Joydeep Pal
# Date: Oct 2022
# Modified: 18 May 2023 (Joydeep Pal)
# Description: Broadly, it transmits custom traffic of ST and BE
# defined by VLAN packets to the destination end-host
# via the local switch.
# Use relevant python script to analyze the performance.

# It uses ssh to run remote commands and
# you should have set up ssh and configured passwordless ssh.

# System Design:
# Using regular Ethernet port (1GbE) of the hosts because of connection to local switch
#                               ____________________
# (PC#1) MultiNIC_TX_port --> | LocalSwitch_P0 --> LocalSwitch_P1 | --> (PC #2) MultiNIC_RX_port
#                              ---------------------

whoami

# Script parameters:
BandwidthTest=100M
BandwidthSTFlow=6.6M # 10M # 6.6M
BandwidthBEFlow=6.6M # 10M # 6.6M
Duration=1
DurationCapture=$(($Duration+10))
RemoteIP=10.114.64.107
LocalCaptureEthernetInterface=enp3s0
LocalCaptureInterfaceIP=10.114.64.70
RemoteCaptureEthernetInterface=enp7s0
RemoteCaptureInterfaceIP=10.114.64.107
Port=4000

TXfile=/tmp/tx_trial.pcap
RXfile=/tmp/rx_trial.pcap
RemoteCapture=$RXfile

#echo 'Step 0a: Configure network namespaces using script, if both tx and rx ports are on same PC'

echo 'Step 1a: Start packet capture on tx and rx'
ssh zenlab@$RemoteIP "tshark -i $RemoteCaptureEthernetInterface -a duration:$DurationCapture -w $RemoteCapture" &
tshark -i $LocalCaptureEthernetInterface -a duration:$DurationCapture -w $TXfile &
sleep 5

echo 'Step 2: Start packet tx (Mixed VLAN Traffic)'
tcpreplay -i $LocalCaptureEthernetInterface -M $BandwidthSTFlow --duration=$Duration '../VLAN_PCAP_Files/NewFlows/Traffic_Flow_vlan(2)_packetsize(100B)_Priority(0)_NoPrio_test8.pcap' &
tcpreplay -i $LocalCaptureEthernetInterface -M $BandwidthBEFlow --duration=$Duration '../VLAN_PCAP_Files/NewFlows/Traffic_Flow_vlan(3)_packetsize(100B)_Priority(0)_NoPrio_test8.pcap'

echo ' '
echo 'Step 3: Check if packet capture successful by checking if file exists in remote node'
sleep 10
ssh zenlab@$RemoteIP "ls /tmp/ | grep rx"

echo 'Step 4: Transfer Tx capture from remote to local system for analysis'
scp -C zenlab@$RemoteIP:$RemoteCapture $RXfile

echo 'Step 5: Convert pcap to csv for automated analysis with python'
args="-T fields -E header=y -E separator=, -e ip.src -e ip.dst -e ip.id -e vlan.id -e vlan.priority \
-e udp.srcport -e udp.dstport -e frame.time_epoch -e frame.len -e udp.length.bad -e udp.length -e data.len"
eval tshark -r $TXfile $args -Y 'udp.dstport==4000' > ../TempCSVfiles/RXv1.csv &
eval tshark -r $RXfile $args -Y 'udp.dstport==4000' > ../TempCSVfiles/TXv1.csv

echo 'Step 6: Process using python script'
./Latency_v5.py $BandwidthSTFlow $BandwidthBEFlow $Duration

echo 'Done !!'
echo ' '
