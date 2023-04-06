#!/bin/bash

# Author: Joydeep Pal
# Date: Nov 2022
# Description: Broadly, it transmits and receives packets (using iperf),
# via NFP running our custom Micro-C program.
# Use relevant python script to analyze the performance.

# It uses ssh to run remote commands and
# you should have set up ssh and configured passwordless ssh.

# Script parameters:
BandwidthTest=100M
PacketSize=1000
Duration=10
DurationCapture=18
ParallelStreams=1

parstr=(1) # 2 3)
bw=(500M) #(100M) #
pktsize=(1000) #(50 1000 1470) #(1470) #
dur=(10) # 60 300)

RemoteIP=10.114.64.248 # 10.114.64.107 #

RemoteCaptureEthernetInterface=enp1s0f0 #enp5s0 #
RemoteCaptureInterfaceIP=11.11.11.18 # 10.114.64.107 #
LocalCaptureEthernetInterface=enp1s0f0 # enp3s0 #
LocalCaptureInterfaceIP=11.11.11.21 # 10.114.64.70 #
Port=3002

TXfile=/tmp/tx_trial.pcap
RXfile=/tmp/rx_trial.pcap
RemoteCapture=$TXfile

# System Design:
# (PC#1) MultiNIC_TX_port --> NFP_P0 --> NFP_P1 --> (PC #2) MultiNIC_RX_port

<< comment
# Assign IP addresses to local and remote interfaces and remove them at the end of the test
sudo ip a add $LocalCaptureInterfaceIP/24 dev $LocalCaptureEthernetInterface
ssh zenlab@$RemoteIP " \
sudo ip a add $RemoteCaptureInterfaceIP/24 dev $RemoteCaptureEthernetInterface"

# Remove assigned IP addresses to local and remote interfaces
sudo ip a del $LocalCaptureInterfaceIP/24 dev $LocalCaptureEthernetInterface
ssh zenlab@$RemoteIP " \
sudo ip a del $RemoteCaptureInterfaceIP/24 dev $RemoteCaptureEthernetInterface"
comment

echo 'Step 0: Configure IP addresses of tx and rx ports, remove at the end'

echo 'Step 1: Start packet rx (iperf server) on local node'
# Note: Kill iperf server processes at the end of the test
iperf -B $LocalCaptureInterfaceIP -s -u -p $Port & #> /dev/null &

TestNo=1
for BandwidthTest in "${bw[@]}"; do
  for PacketSize in "${pktsize[@]}"; do
    for Duration in "${dur[@]}"; do
      for ParallelStreams in "${parstr[@]}"; do
        for ((TrialNo=1; TrialNo <= 1; TrialNo++)); do
          $DurationCapture=$(($Duration+10))
          echo $PacketSize, $Duration, $DurationCapture, $BandwidthTest, $ParallelStreams
          echo "Trial:"$TrialNo, "Test No.:"$TestNo
          echo 'Step 2: Running PacketCapture on Tx and Rx nodes'
          tshark -i $LocalCaptureEthernetInterface -Q -a duration:$DurationCapture -w $RXfile &
          ssh zenlab@$RemoteIP "tshark -i $RemoteCaptureEthernetInterface -Q -a duration:$DurationCapture -w $RemoteCapture" &

          echo 'Step 3: Run iperf client (Tx) command in remote node'
          sleep 2
          ssh zenlab@$RemoteIP " \
          iperf -B $RemoteCaptureInterfaceIP -c $LocalCaptureInterfaceIP -u -t $Duration \
          -p $Port -P $ParallelStreams -l $PacketSize -b $BandwidthTest >/dev/null && \
          ls /tmp/ | grep tx \
          "

          echo 'Step 4: Transfer Tx capture from remote to local system for analysis'
          sleep 8
          scp -C zenlab@$RemoteIP:$RemoteCapture $TXfile

          echo 'Step 5: Convert pcap to csv for automated analysis with python'
          args="-T fields -E header=y -E separator=, \
          -e ip.id -e ip.src -e ip.dst -e udp.srcport -e udp.dstport \
          -e frame.time_epoch -e udp.length.bad -e udp.length -e data.len"
          args2='!icmp && !mdns && !arp && udp.dstport==3002'
          eval tshark -r $TXfile $args -Y \'$args2\' > ../TempCSVfiles/TXv1.csv &
          eval tshark -r $RXfile $args -Y \'$args2\' > ../TempCSVfiles/RXv1.csv

          echo 'Step 6: Process using python script'

          ((TestNo=TestNo+1))
        done
      done
    done
  done
done

killall iperf
echo 'Done !!'
