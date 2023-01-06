#!/bin/bash

tcpreplay -l 500 -i enp1s0f0 ./udp_v2.pcap
tcpreplay -l 500 -i enp1s0f0 ./udp_v3.pcap
tcpreplay -l 500 -i enp1s0f0 ./udp_v2.pcap
tcpreplay -l 500 -i enp1s0f0 ./udp_v3.pcap
tcpreplay -l 500 -i enp1s0f0 ./udp_v2.pcap
tcpreplay -l 500 -i enp1s0f0 ./udp_v3.pcap

#xterm -title "VLAN2" -hold -e "sudo tcpreplay -l 500000 -i enp1s0f0 ./udp_v2.pcap" &
#xterm -title "VLAN3" -hold -e "sudo tcpreplay -l 500000 -i enp1s0f0 ./udp_v3.pcap" &

sleep 1

