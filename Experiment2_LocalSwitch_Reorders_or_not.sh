#!/bin/bash

# You should have set up ssh and configured passwordless ssh.
RemoteIP=10.114.64.107
ScriptFolder=~/Documents/Scripts
TXfile=/tmp/tx_trial1.pcap
RXfile=/tmp/rx_trial1.pcap
RemoteCapture=$TXfile

## Using 1 GbE ethernet port of multiNIC CPU
## Tx, Rx Switch Nodes on different PCs
## (PC#1) MultiNIC_TX_port --> LocalSwitch_P0 --> LocalSwitch_P1 --> (PC #2) MultiNIC_RX_port

echo "Step 1: Run iperf server (Rx) in local node as daemon (background process)"
### Kill iperf server processes at the end of the test
#iperf -B $LocalCaptureInterfaceIP -sD -u -p $Port &
# -1 with iperf3 closes iperf3 server automatically after 1 session, or you can kill iperf3 at the end
iperf3 -s -p 4000 -1 &
sleep 2

echo "Step 2: Running PacketCapture on Tx and Rx nodes"
tshark -i $LocalCaptureEthernetInterface -B 5 -a duration:$DurationX -w $RXfile &
#ssh zenlab@$RemoteIP "tshark -i $RemoteCaptureEthernetInterface -B 20 -Q -a duration:$DurationX -w $RemoteCapture" &
ssh zenlab@$RemoteIP "tshark -i enp5s0 -B 20 -Q -a duration:30 -w $RemoteCapture" &
# Or you can start an xterm and execute ssh command to segregate ssh output to this xterm
# rather than in the same terminal
nohup xterm -hold -e ssh zenlab@10.114.64.107 "" &
sleep 5

echo "Step 3: Run iperf client (Tx) command in remote node"
: '
'
# Iperf gives transport layer bandwidth, so actual bandwidth is a little more
### iperf3 flags
# -b 0 -> Max bandwidth of port (Verified)
# -t for time, -n for bytes, -k for no. of pkts
# -P for number of parallel streams, max bandwidth gets divided between these streams
# -l for length of UDP/TCP payload, related to fragmentation
# Also length increase -> bandwidth utilisation increase
ssh zenlab@$RemoteIP " \
#iperf3 -c 10.114.64.107 -u -l 1000 -t 5 -p 4000 -b 100M && \
iperf -B $RemoteCaptureInterfaceIP -c $LocalCaptureInterfaceIP -u -t $Duration \
-p $Port -P 2 -b $BandwidthTest >/dev/null && \
ls /tmp/ | grep tx \
"

### Step 4: Transfer Tx capture from remote to local system for analysis
sleep 8
#scp -C zenlab@$RemoteIP:$RemoteCapture $TXfile
scp zenlab@10.114.64.107:$RemoteRxfile $RXfile

# Give permission to folder where you are saving the pcap file by 'chmod 777'

### Step 5: Convert pcap to csv for automated analysis with python
args="-T fields -E header=y -E separator=, \
-e ip.id -e ip.src -e ip.dst -e udp.srcport -e udp.dstport \
-e frame.time_epoch -e udp.length.bad -e udp.length -e data.len"
eval tshark -r $TXfile $args -Y 'udp.dstport==4000' > TempCSVfiles/TXv1.csv
eval tshark -r $RXfile $args -Y 'udp.dstport==4000' > TempCSVfiles/RXv1.csv

### Step 6: Process using python script
./OutOfOrderCount.py
#./Latency_v2.py

### Step 7: Open wireshark captures
# wireshark -r $TXfile &
# wireshark -r $RXfile &
# If namespaces are used, you can open wireshark captures using below commands
#sudo ip netns exec nsTX tshark -i enp1s0f0 -a duration:2 -w ../TXv1.pcap &
#sudo ip netns exec nsRX tshark -i enp1s0f1 -a duration:2 -w ../RXv1.pcap

#killall iperf
echo "Done !!"