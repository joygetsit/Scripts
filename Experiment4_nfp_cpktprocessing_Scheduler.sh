#!/bin/bash

# Author: Joydeep Pal
# Date: 10 Jan 2023
# Description: Broadly, it transmits mixed traffic of ST and BE 
# defined by vlan packets (ID:2 and ID:3) to the destination end-host 
# via our Micro-C program on NFP and then analyzes the performance.
# It uses ssh to run remote commands and
# you should have set up ssh and configured passwordless ssh.

# System Design:
# (PC#1) MultiNIC_TX_port --> NFP_P0 --> NFP_P1 --> (PC #2) MultiNIC_RX_port

DurationX=15

RemoteIP=10.114.64.248 # 10.114.64.107 #

LocalCaptureEthernetInterface=enp1s0f0 # enp3s0 #
#LocalCaptureInterfaceIP=11.11.11.10 # 10.114.64.70 #
RemoteCaptureEthernetInterface=enp1s0f0 #enp5s0 #
#RemoteCaptureInterfaceIP=11.11.11.11 # 10.114.64.107 #

TXfile=/tmp/tx_trial.pcap
RXfile=/tmp/rx_trial.pcap
RemoteCapture=$RXfile

# Possible errors and resolutions:
# 1. Assign permissions to $TXfile and $RXfile

# Assign IP addresses to local and remote interfaces and remove them at the end of the test
# sudo ip a add $LocalCaptureInterfaceIP/24 dev $LocalCaptureEthernetInterface
# sudo ip a add 11.11.11.10/24 dev enp1s0f0
# ssh zenlab@$RemoteIP \
# "sudo ip a add $RemoteCaptureInterfaceIP/24 dev $RemoteCaptureEthernetInterface"
# sudo ip a add 11.11.11.11/24 dev enp1s0f0


# If Tx and Rx nodes are on same PC, i.e PC #1 and #2 are same,
# configure multiNIC's Ethernet ports i.e.
# isolate using network namespaces by running sudo ./configure_multinic.sh
# And remove this configuration at the end of the experiment.

ssh zenlab@$RemoteIP "tshark -i $RemoteCaptureEthernetInterface -a duration:$DurationX -w $RemoteCapture" &
tshark -i $LocalCaptureEthernetInterface -a duration:$DurationX -w $TXfile &
sleep 2

echo "Step 2: Sending Mixed traffic"
tcpreplay -i enp1s0f0 -M 100 --duration=4 ../vlan_pcap_Files/create_VLAN_packets/Mixed_VLAN_pkts.pcap

echo "Step 3: Check and get command in remote node"
sleep 2
ssh zenlab@$RemoteIP "ls /tmp/ | grep rx"        

echo "Step 4: Transfer Tx capture from remote to local system for analysis"
sleep 2
scp -C zenlab@$RemoteIP:$RemoteCapture $RXfile

sleep 2
echo "Step 5: Open wireshark captures"
#wireshark -r $TXfile &
#wireshark -r $RXfile &

echo "Step 6: Convert pcap to csv for automated analysis with python"
args="-T fields -E header=y -E separator=, -e ip.src -e ip.id -e vlan.id -e frame.time_epoch -e frame.len"
eval tshark -r $TXfile $args > TempCSVfiles/TXv1.csv &
eval tshark -r $RXfile $args > TempCSVfiles/RXv1.csv

echo "Step 7: Process using python script"
./Latency_v3.py

echo "Done !!"

# Remove assigned IP addresses to local and remote interfaces
#ssh zenlab@$RemoteIP
#"sudo ip a del $RemoteCaptureInterfaceIP/24 dev $RemoteCaptureEthernetInterface"
#sudo ip a del $LocalCaptureInterfaceIP/24 dev $LocalCaptureEthernetInterface
