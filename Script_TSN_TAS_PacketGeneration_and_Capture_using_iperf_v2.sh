#!/bin/bash

xterm -title "UDPRx#1" -hold -e "sudo ip netns exec nsRX iperf -s -u -p 4000" &
xterm -title "UDPRx#2" -hold -e "sudo ip netns exec nsRX iperf -s -u -p 4001" &
xterm -title "UDPRx#3" -hold -e "sudo ip netns exec nsRX iperf -s -u -p 4002" &

sudo ./capturelatency.sh &

sleep 1

xterm -title "UDP#1" -hold -e "sudo ip netns exec nsTX iperf -c 11.11.11.11 -u -t 1 -p 4000 -i 1 -b 50pps" &
xterm -title "UDP#2" -hold -e "sudo ip netns exec nsTX iperf -c 11.11.11.11 -u -t 1 -p 4001 -i 1 -b 20pps" &
xterm -title "UDP#3" -hold -e "sudo ip netns exec nsTX iperf -c 11.11.11.11 -u -t 1 -p 4002 -i 1 -b 50pps"
