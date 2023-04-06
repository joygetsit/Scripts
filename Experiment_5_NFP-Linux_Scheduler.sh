#!/bin/bash

# Author: Joydeep Pal
# Date: 10 Jan 2023
# Description: Broadly, it transmits custom traffic of ST and BE
# defined by VLAN packets to the destination end-host
# via NFP running our custom Micro-C program.
# Use relevant python script to analyze the performance.

# It uses ssh to run remote commands and
# you should have set up ssh and configured passwordless ssh.

# System Design:
# (PC#1) MultiNIC_TX_port --> NFP_P0 --> NFP_P1 --> (PC #2) MultiNIC_RX_port

# Script parameters:
BandwidthTest=100M
BandwidthSTFlow=10M
BandwidthBEFlow=10M
Duration=1
DurationCapture=$(($Duration+15))
RemoteIP=10.114.64.117 # 10.114.64.107 #
LocalCaptureEthernetInterface=enp1s0f0 # enp3s0 #
#LocalCaptureInterfaceIP=11.11.11.10 # 10.114.64.70 #
RemoteCaptureEthernetInterface=enp4s0f0 #enp5s0 #
#RemoteCaptureInterfaceIP=11.11.11.11 # 10.114.64.107 #

TXfile=/tmp/tx_trial.pcap
RXfile=/tmp/rx_trial.pcap
RemoteCapture=$RXfile

echo 'Step 0a: Configure network namespaces using script, if both tx and rx ports are on same PC'

echo 'Step 1: Start packet capture on tx and rx'
ssh zenlab@$RemoteIP "tshark -i $RemoteCaptureEthernetInterface -a duration:$DurationCapture -w $RemoteCapture" &
tshark -i $LocalCaptureEthernetInterface -a duration:$DurationCapture -w $TXfile &
sleep 5

echo 'Step 2: Start packet tx (Mixed VLAN Traffic)'
#tcpreplay -i $LocalCaptureEthernetInterface -M $BandwidthTest --duration=$Duration ../VLAN_PCAP_Files/Equally_Mixed_VLAN_packets_fixed_data_length.pcap
tcpreplay -i $LocalCaptureEthernetInterface -M $BandwidthSTFlow --duration=$Duration ../VLAN_PCAP_Files/iperf_3003_VLAN_3_packets_Size_1000B_test6.pcap &
tcpreplay -i $LocalCaptureEthernetInterface -M $BandwidthBEFlow --duration=$Duration ../VLAN_PCAP_Files/iperf_3002_VLAN_2_packets_Size_1000B_test6.pcap

echo 'Step 3: Check if packet capture successful by checking if file exists in remote node'
sleep 10
ssh zenlab@$RemoteIP "ls /tmp/ | grep rx"        

echo 'Step 4: Transfer Tx capture from remote to local system for analysis'
scp -C zenlab@$RemoteIP:$RemoteCapture $RXfile

echo 'Step 5: Convert pcap to csv for automated analysis with python'
args="-T fields -E header=y -E separator=, -e ip.src -e ip.id -e udp.dstport -e vlan.id -e frame.time_epoch -e frame.len"
eval tshark -r $RXfile $args > ../TempCSVfiles/RXv2.csv &
eval tshark -r $TXfile $args > ../TempCSVfiles/TXv2.csv

echo 'Step 6: Process using python script'
./Latency_v4_LinuxNFP.py $BandwidthSTFlow $BandwidthBEFlow $Duration

echo 'Done !!'
echo ' '
