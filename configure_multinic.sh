#!/bin/bash

# Author: Joydeep Pal
# Date: Nov 2022
# Description: Configures MultiNIC as isolated network namespaces with
# access to different physical ports. This helps when sending and receiving ports
# are on the same PC and iperf/ping commands have to be used.
# Otherwise, these commands don't send packets out to the wire
# and kernel routes it internally.

# Run as sudo

# NOTE: To delete created namespaces, run above command with argument 'delete'
# i.e. sudo ./configure_multinic.sh delete

PORT_0=enp1s0f0
PORT_1=enp1s0f1
IPTX=11.11.11.10
IPRX=11.11.11.11
NW_Namespace_0=nsTX
NW_Namespace_1=nsRX
MAC_ADDRESS_0=00:1b:21:c2:54:40
MAC_ADDRESS_1=00:1b:21:c2:54:42

# Show all network devices/interfaces
ip a 

# Creates network namespaces 
# (acts like computer nodes, with deactivated loopback devices)
ip netns add $NW_Namespace_0
ip netns add $NW_Namespace_1
ip netns

# Assign the two Ethernet ports to respective network namespaces
ip link set $PORT_0 netns $NW_Namespace_0
ip link set $PORT_1 netns $NW_Namespace_1

# Assign IP addressess to the interafces 
# to make them functional and activate them
ip -n $NW_Namespace_0 addr add $IPTX/24 dev $PORT_0
ip -n $NW_Namespace_1 addr add $IPRX/24 dev $PORT_1
ip -n $NW_Namespace_0 link set $PORT_0 up
ip -n $NW_Namespace_1 link set $PORT_1 up

echo "Root namespace ports"
ip a
echo "Namespace $NW_Namespace_0 ports"
ip -n $NW_Namespace_0 a
echo "Namespace $NW_Namespace_1 ports"
ip -n $NW_Namespace_1 a

<< comment
# This may not be needed, verify once and remove

# For enabling successful ping/iperf between the two namespaces,
# add static arp entries to the namesapces
ip netns exec $NW_Namespace_0 arp -s $IPRX $MAC_ADDRESS_1
ip netns exec $NW_Namespace_1 arp -s $IPTX $MAC_ADDRESS_0
comment

if [ "$1" = delete ]; then
	echo "Removing user namespaces"
	ip netns delete $NW_Namespace_0
	ip netns delete $NW_Namespace_1
	sleep 1
	ip a
fi
