#!/bin/bash

# Author: Joydeep Pal
# Date: Nov 2022
# Description: Broadly, it transmits and receives packets (using iperf),
# via NFP running NIC firmware (nic_firmware).
# Use relevant python script to analyze the performance.

# It uses ssh to run remote commands and
# you should have set up ssh and configured passwordless ssh.

# Script parameters:
BandwidthTest=500M
PacketSize=1000
Duration=5
DurationCapture=10
ParallelStreams=1

RemoteIP=10.114.64.107

TxIP=11.11.11.10
RxIP=11.11.11.11
Port=4000

Txfile=/tmp/tx_trial.pcap
Rxfile=/tmp/rx_trial.pcap

# System Design:
# Using Netronome Ethernet ports as Switch ports
# (PC#1) MultiNIC_TX_port --> NFP_P0 --> NFP_P1 --> (PC #1) MultiNIC_RX_port

<< comment
# Notes on iperf and iperf3
# Iperf gives transport layer bandwidth, so actual bandwidth is a little more
## iperf3 flags
# -b 0 -> Max bandwidth of port (Verified)
# -t for time, -n for bytes, -k for no. of pkts
# -P for number of parallel streams, max bandwidth gets divided between these streams
# -l for length of UDP/TCP payload, related to fragmentation
# Also length increase -> bandwidth utilisation increase

# Kill iperf server processes at the end of the test
# The argument '-1' with iperf3 closes iperf3 server automatically after 1 session,
# or you can kill iperf3 at the end.
# Better to kill it at the end of the test to maintain uniformity in your codes

# To segregate ssh output to this xterm rather than in the same terminal,
# start an xterm and execute ssh command
nohup xterm -hold -e ssh zenlab@10.114.64.107 "" &

# Possible errors and resolutions:
# 1. Assign permissions to $TXfile and $RXfile
comment

echo 'Step 0a: Configure network namespaces using script, if both tx and rx ports are on same PC'
echo 'Step 0b: Configure Netronome as a switch using the script'
echo 'Step 0c: Configure IP addresses of tx and rx ports, remove at the end'

echo 'Step 1: Start packet capture (using tshark) on the Ethernet ports.
      Currently running on Netronome ports'
ssh zenlab@$RemoteIP "sudo tshark -i enp1s0np0 --autostop duration:$DurationCapture -w /tmp/tx_nfp_p0_trial1.pcap" &
ssh zenlab@$RemoteIP "sudo tshark -i enp1s0np1 --autostop duration:$DurationCapture -w /tmp/tx_nfp_p1_trial1.pcap" &

echo 'Step 2: Start packet capture on tx and rx MultiNIC ports and save to /tmp folder'
sudo ip netns exec nsTX wireshark -k -i enp1s0f0 --autostop duration:$DurationCapture -Y udp.dstport==$Port -w $Txfile &
sudo ip netns exec nsRX wireshark -k -i enp1s0f1 --autostop duration:$DurationCapture -Y udp.dstport==$Port -w $Rxfile &

echo 'Step 3: Start packet rx (iperf3 server)'
sudo ip netns exec nsRX iperf3 -s -p $Port -1 &
sleep 2

echo 'Step 4: Start packet tx (iperf3 client)'
sudo ip netns exec nsTX iperf3 -c $RxIP -u -l $PacketSize -t $Duration -p $Port -b $BandwidthTest -P $ParallelStreams
<< comment
echo 'Step 4: Ping from TX to RX'
sudo ip netns exec nsTX ping -f -B -Q 5 -c 10 $RxIP
comment

echo 'Step 5: Convert pcap to csv'
args="-T fields -E header=y -E separator=, -e ip.id -e ip.src -e ip.dst \
-e udp.srcport -e udp.dstport -e frame.time_epoch"
sudo tshark -r $Txfile $args -Y 'udp.dstport==$Port' > ../TempCSVfiles/TXv1.csv
sudo tshark -r $Rxfile $args -Y 'udp.dstport==$Port' > ../TempCSVfiles/RXv1.csv

echo 'Step 6: Process using python script'

echo 'Step 7: Open wireshark captures'
# wireshark -r $TXfile &
# wireshark -r $RXfile &
