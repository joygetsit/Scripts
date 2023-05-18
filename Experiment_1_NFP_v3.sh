#!/bin/bash

# Author: Joydeep Pal
# Date: Nov 2022
# Modified: 10 Jan 2023, 18 May 2023 (Joydeep Pal)
# Description: Broadly, it transmits custom traffic of ST and BE
# defined by VLAN packets to the destination end-host
# via NFP running a firmware
# either NIC firmware (nic_firmware) or our custom Micro-C program.
# Use relevant python script to analyze the performance.

# It uses ssh to run remote commands and
# you should have set up ssh and configured passwordless ssh.

# System Design:
#                               ____________________
# (PC#1) MultiNIC_TX_port --> | NFP_P0 --> NFP_P1 | --> (PC #2) MultiNIC_RX_port
#                              ---------------------

whoami

# Argument for experiment, default (Micro-C) or nic_firmware
echo 'State the experiment: nic_firmware (or) default -> custom Micro-C program'

if [ $# -eq 0 ]; then
Experiment='custom'
else
Experiment=$1
fi
echo ${Experiment}

# Script parameters:
BandwidthTest=100M
BandwidthSTFlow=1k # 10M # 6.6M
BandwidthBEFlow=1k # 10M # 6.6M
Duration=1
DurationCapture=$(($Duration+10))
RemoteIP=10.114.64.248
NFPIP=10.114.64.107
LocalCaptureEthernetInterface=enp1s0f0
#LocalCaptureInterfaceIP=10.114.64.70
RemoteCaptureEthernetInterface=enp1s0f1
#RemoteCaptureInterfaceIP=10.114.64.107

TXfile=/tmp/tx_trial.pcap
RXfile=/tmp/rx_trial.pcap
RemoteCapture=$RXfile

#echo 'Step 0a: Configure network namespaces using script, if both tx and rx ports are on same PC'

echo 'Step 0b: Configure Netronome as a switch using relevant script'

echo 'Step 1: Start packet capture on tx and rx'
ssh zenlab@$RemoteIP "tshark -i $RemoteCaptureEthernetInterface -a duration:$DurationCapture -w $RemoteCapture" &
tshark -i $LocalCaptureEthernetInterface -a duration:$DurationCapture -w $TXfile &

if [ $Experiment == "nic_firmware" ]; then
echo 'Step 1b: Start packet capture on NFP Ethernet ports.'
ssh zenlab@$NFPIP " \
tshark -i enp1s0np0 -a duration:$DurationCapture -w /tmp/tx_nfp_p0.pcap && \
tshark -i enp1s0np1 -a duration:$DurationCapture -w /tmp/tx_nfp_p1.pcap \
" &
fi

sleep 5

echo ' '
echo 'Step 2: Start packet tx (Mixed VLAN Traffic)'
tcpreplay -i $LocalCaptureEthernetInterface -M $BandwidthSTFlow --duration=$Duration '../VLAN_PCAP_Files/NewFlows/Traffic_Flow_vlan(2)_packetsize(100B)_Priority(0)_NoPrio_test8.pcap' &
tcpreplay -i $LocalCaptureEthernetInterface -M $BandwidthBEFlow --duration=$Duration '../VLAN_PCAP_Files/NewFlows/Traffic_Flow_vlan(3)_packetsize(100B)_Priority(0)_NoPrio_test8.pcap'
#tcpreplay -i $LocalCaptureEthernetInterface -M $BandwidthBEFlow --duration=$Duration '../VLAN_PCAP_Files/NewFlows/Traffic_Flow_vlan(4)_packetsize(1000B)_Priority(0)_NoPrio_test8.pcap' &
#tcpreplay -i $LocalCaptureEthernetInterface -M $BandwidthSTFlow --duration=$Duration '../VLAN_PCAP_Files/ArchiveFlows/VLAN_2_packets_Size_1000B_NoPrio_test4.pcap' &
#tcpreplay -i $LocalCaptureEthernetInterface -M $BandwidthBEFlow --duration=$Duration '../VLAN_PCAP_Files/ArchiveFlows/VLAN_3_packets_Size_1000B_NoPrio_test4.pcap' &
#tcpreplay -i $LocalCaptureEthernetInterface -M $BandwidthTest --duration=$Duration ../VLAN_PCAP_Files/Equally_Mixed_VLAN_packets_fixed_data_length.pcap

echo ' '
echo 'Step 3: Check if packet capture successful by checking if file exists in remote node'
sleep 10
ssh zenlab@$RemoteIP "ls -al /tmp/ | grep rx"

echo 'Step 4: Transfer Tx capture from remote to local system for analysis'
scp -C zenlab@$RemoteIP:$RemoteCapture $RXfile

echo 'Step 5: Convert pcap to csv for automated analysis with python'
args="-T fields -E header=y -E separator=, -e ip.src -e ip.dst -e ip.id -e vlan.id -e vlan.priority \
-e udp.srcport -e udp.dstport -e frame.time_epoch -e frame.len"
eval tshark -r $RXfile $args > ../TempCSVfiles/RXv1.csv &
eval tshark -r $TXfile $args > ../TempCSVfiles/TXv1.csv

echo 'Step 6: Process using python script'
./Latency_v5.py $BandwidthSTFlow $BandwidthBEFlow $Duration

echo 'Done !!'
echo ' '
