#!/bin/bash

# Author: Joydeep Pal
# Date: Nov 2022
# Description: Broadly, it transmits and receives packets using iperf,
# through our MicroC program on NFP
# and then analyzes the performance.
# It uses ssh to run remote commands and
# you should have set up ssh and configured passwordless ssh.

parstr=(1) # 2 3)
bw=(500M) #(100M) #
pktsize=(1000) #(50 1000 1470) #(1470) #
dur=(10) # 60 300)

#ParallelStreams=1
#BandwidthTest=100M
#PacketSize=1000
#Duration=10
#DurationX=18

Port=3002
RemoteIP=10.114.64.248 # 10.114.64.107 #
RemoteCaptureEthernetInterface=enp1s0f0 #enp5s0 #
RemoteCaptureInterfaceIP=11.11.11.18 # 10.114.64.107 #
LocalCaptureEthernetInterface=enp1s0f0 # enp3s0 #
LocalCaptureInterfaceIP=11.11.11.21 # 10.114.64.70 #
ScriptFolder=~/Documents/Scripts
TXfile=/tmp/tx_trial.pcap
RXfile=/tmp/rx_trial.pcap
RemoteCapture=$TXfile

# Possible errors and resolutions:
# 1. Assign permissions to $TXfile and $RXfile

# Assign IP addresses to local and remote interfaces and remove them at the end of the test
# sudo ip a add $LocalCaptureInterfaceIP/24 dev $LocalCaptureEthernetInterface
#sudo ip a add 11.11.11.21/24 dev enp1s0f0
#ssh zenlab@$RemoteIP \
#"sudo ip a add $RemoteCaptureInterfaceIP/24 dev $RemoteCaptureEthernetInterface"
#sudo ip a add 11.11.11.18/24 dev enp1s0f0

# System Design:
# (PC#1) MultiNIC_TX_port --> NFP_P0 --> NFP_P1 --> (PC #2) MultiNIC_RX_port

# If Tx and Rx nodes are on same PC, i.e PC #1 and #2 are same,
# configure multiNIC's Ethernet ports i.e.
# isolate using network namespaces by running sudo ./configure_multinic.sh
# Undo by running above command with argument "delete"

echo "Step 1: Run iperf server (Rx) in local node"
# Note: Kill iperf server processes at the end of the test
iperf -B $LocalCaptureInterfaceIP -s -u -p $Port & #> /dev/null &
sleep 2

TestNo=1
for BandwidthTest in "${bw[@]}"; do
  for PacketSize in "${pktsize[@]}"; do
    for Duration in "${dur[@]}"; do
      for ParallelStreams in "${parstr[@]}"; do
        for ((TrialNo=1; TrialNo <= 1; TrialNo++)); do
          DurationX=$(($Duration+10))
          echo $PacketSize, $Duration, $DurationX, $BandwidthTest, $ParallelStreams
          echo "Trial:"$TrialNo, "Test No.:"$TestNo
          echo "Step 2: Running PacketCapture on Tx and Rx nodes"
          tshark -i $LocalCaptureEthernetInterface -Q -a duration:$DurationX -w $RXfile &
          ssh zenlab@$RemoteIP "tshark -i $RemoteCaptureEthernetInterface -Q -a duration:$DurationX -w $RemoteCapture" &

          echo "Step 3: Run iperf client (Tx) command in remote node"
          sleep 2
          ssh zenlab@$RemoteIP " \
          iperf -B $RemoteCaptureInterfaceIP -c $LocalCaptureInterfaceIP -u -t $Duration \
          -p $Port -P $ParallelStreams -l $PacketSize -b $BandwidthTest >/dev/null && \
          ls /tmp/ | grep tx \
          "

          ### Step 4: Transfer Tx capture from remote to local system for analysis
          sleep 8
          scp -C zenlab@$RemoteIP:$RemoteCapture $TXfile

          ### Step 5: Convert pcap to csv for automated analysis with python
          args="-T fields -E header=y -E separator=, \
          -e ip.id -e ip.src -e ip.dst -e udp.srcport -e udp.dstport \
          -e frame.time_epoch -e udp.length.bad -e udp.length -e data.len"
          args2='!icmp && !mdns && !arp && udp.dstport==3002'
          eval tshark -r $TXfile $args -Y \'$args2\' > TempCSVfiles/TXv1.csv &
          eval tshark -r $RXfile $args -Y \'$args2\' > TempCSVfiles/RXv1.csv

          ### Step 6: Process using python script
          # ./CorruptedPktsCount.py $PacketSize $BandwidthTest $Duration
          ./OutOfOrderCount.py
          ### Step 7: Open wireshark captures
          # wireshark -r $TXfile &
          # wireshark -r $RXfile &
          ((TestNo=TestNo+1))
        done
      done
    done
  done
done

killall iperf
echo "Done !!"

# Remove assigned IP addresses to local and remote interfaces
#ssh zenlab@$RemoteIP
#"sudo ip a del $RemoteCaptureInterfaceIP/24 dev $RemoteCaptureEthernetInterface"
#sudo ip a del $LocalCaptureInterfaceIP/24 dev $LocalCaptureEthernetInterface

<< comment
### Step 2: Open wireshark capture on multinic ports and save to tmp folder
sudo ip netns exec nsTX wireshark -i enp1s0f0 -k --autostop duration:10 -Y udp.dstport==4000 -w /tmp/tx_multinic_trial1.pcap &
sudo ip netns exec nsRX wireshark -i enp1s0f1 -k --autostop duration:10 -Y udp.dstport==4000 -w /tmp/rx_multinic_trial1.pcap &
sleep 1

echo "Step 3: Ping from TX to RX"
sudo ip netns exec nsTX ping -f -B -Q 5 -c 10 11.11.11.11

#### Step 5: Start iperf3 server on multinic Rx port
#xterm -hold -e 'sudo ip netns exec nsRX iperf3 -s -p 4000 -1' &
#sleep 1
#
#### Step 6: Start iperf3 client to transmit on multinic Tx port
#xterm -hold -e 'sudo ip netns exec nsTX iperf3 -c 11.11.11.11 -u -l 1000 -t 5 -p 4000 -b 100M' #-P 2
comment
