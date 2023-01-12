#!/bin/bash

# Author: Joydeep Pal
# Date: Nov 2022
# Description: Broadly, it transmits and receives packets using iperf,
# through out NIC firmware on NFP (nic_firmware)
# and then analyzes the performance.

## If Netronome Agilio is running nic_firmware and has to be configured as a switch/bridge
## Use sudo ./configure_netronome_as_bridge.sh on Netronome system
#ssh zenlab@10.114.64.107 "sudo ./configure_netronome_as_bridge.sh"
## One way is to send script to that system using scp and running the script remotely i.e.
#LocalFile=~"$ScriptFolder"/configure_netronome_as_bridge.sh
#RemoteFile=~/Documents/tests/configure_netronome_as_bridge.sh
#scp $LocalFile zenlab@10.114.64.107:$RemoteFile
## Execute and show ouput in local xterm
#xterm -hold -e ssh -t zenlab@10.114.64.107 "sudo  Documents/tests/configure_netronome_as_bridge.sh" &
## Doesn't show all expected output, but I don't need to solve this now
## To remove Switch functionality and free the Ethernet ports, so that Netronome behaves as NIC,
## run command with argument "delete"
## Other way is to use ssh to run this local script remotely without transferring the script

### Step 3: Open tshark capture file on Netronome ports
xterm -hold -e ssh -t zenlab@10.114.64.107 "sudo tshark -i enp1s0np0 --autostop duration:30 \
-w /tmp/tx_nfp_p0_trial1.pcap" &
xterm -hold -e ssh -t zenlab@10.114.64.107 "sudo tshark -i enp1s0np1 --autostop duration:30 \
-w /tmp/tx_nfp_p1_trial1.pcap" &
sleep 20

### Step 4: Open wireshark capture on multinic ports and save to tmp folder
sudo ip netns exec nsTX wireshark -i enp1s0f0 -k --autostop duration:10 -Y udp.dstport==4000 -w /tmp/tx_multinic_trial1.pcap &
sudo ip netns exec nsRX wireshark -i enp1s0f1 -k --autostop duration:10 -Y udp.dstport==4000 -w /tmp/rx_multinic_trial1.pcap &
sleep 1

### Step 5: Start iperf3 server on multinic Rx port
xterm -hold -e 'sudo ip netns exec nsRX iperf3 -s -p 4000 -1' &
sleep 1

### Step 6: Start iperf3 client to transmit on multinic Tx port
xterm -hold -e 'sudo ip netns exec nsTX iperf3 -c 11.11.11.11 -u -l 1000 -t 5 -p 4000 -b 500M' #-P 2

### Step 7: Convert pcap to csv
sudo tshark -r /tmp/rx_multinic_trial1.pcap -T fields -E header=y -E separator=, \
-e ip.id -e ip.src -e ip.dst -e udp.srcport -e udp.dstport -e frame.time_epoch -Y 'udp.dstport==4000' > TempCSVfiles/TXv1.csv
sudo tshark -r /tmp/tx_multinic_trial1.pcap -T fields -E header=y -E separator=, \
-e ip.id -e ip.src -e ip.dst -e udp.srcport -e udp.dstport -e frame.time_epoch -Y 'udp.dstport==4000' > TempCSVfiles/RXv1.csv

### Step 8: Process using python script
./OutOfOrderCount.py




