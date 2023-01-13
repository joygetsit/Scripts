#!/bin/bash

# Author: Joydeep Pal
# Date: Nov 2022
# Description: Configures Netronome as a bridge/switch
# using Linux 'ip link' utility. Run this on system hosting Netronome card.
# Command to configure - 'sudo ./Script.sh'
# Command to remove configuration - 'sudo ./Script.sh delete'

# Run as sudo

<< comment
Notes:
# If Netronome Agilio is running nic_firmware and has to be configured as a switch/bridge
# Use sudo ./Configure_NFP_as_switch.sh on Netronome system
ssh zenlab@10.114.64.107 "sudo ./Configure_NFP_as_switch.sh"
# One way is to send script to that system using scp and running the script remotely i.e.
LocalFile=~"$ScriptFolder"/Configure_NFP_as_switch.sh
RemoteFile=~/Documents/tests/Configure_NFP_as_switch.sh
scp $LocalFile zenlab@10.114.64.107:$RemoteFile
# Execute and show ouput in local xterm
xterm -hold -e ssh -t zenlab@10.114.64.107 "sudo  Documents/tests/Configure_NFP_as_switch.sh" &
# Doesn't show all expected output, but I don't need to solve this now
# To remove Switch functionality and free the Ethernet ports, so that Netronome behaves as NIC,
# run command with argument "delete"
##Other way is to use ssh to run this local script remotely without transferring the script
comment

<< comment
# To see output of ssh on local xterm and have it stay when the ssh command completes execution, run following command:
xterm -hold -e ssh -t 'username'@'RemoteIP' "Command"
# To see output on separate local xterm, run following command:
xterm -hold -e "Command"
comment

echo "Current Time = "`date`
echo "HOSTNAME = "`hostname`
echo "USER ID = "`whoami`
echo "IP ADDRESS = "`ip a s enp5s0 | grep "inet " | cut -f6 -d " "`

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


