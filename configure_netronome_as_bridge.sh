#!/bin/bash

echo "Current Time = "`date`
echo "HOSTNAME = "`hostname`
echo "USER ID = "`whoami`
echo "IP ADDRESS = "`ip a s enp5s0 | grep "inet " | cut -f6 -d " "`


#ip a
sudo ip link add Switch1 type bridge
sudo ip link set enp1s0np0 master Switch1
sudo ip link set enp1s0np1 master Switch1
sudo ip link set Switch1 up
echo "Netronome set up as a switch"
ip a

if [ "$1" = delete ]; then
	echo "Removing bridge"
	ip link del Switch1
	sleep 1
	ip a
fi


