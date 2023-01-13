#!/bin/bash

xterm -title "VLAN2" -hold -e "sudo tcpreplay -K -l 500000 -M 1000 -i enp1s0f0 ../../vlan_pcap_Files/udp_v2.pcap" &
xterm -title "VLAN3" -hold -e "sudo tcpreplay -K -l 500000 -M 1000 -i enp1s0f0 ../../vlan_pcap_Files/udp_v3.pcap" &

: << 'END'
xterm -title "VLAN2" -hold -e "sudo tcpreplay -l 5000000 -i enp1s0f0 ./udp_v2.pcap" &
xterm -title "VLAN3" -hold -e "sudo tcpreplay -l 5000000 -i enp1s0f0 ./udp_v3.pcap" &
xterm -title "VLAN2_1" -hold -e "sudo tcpreplay -l 5000000 -i enp1s0f0 ./udp_v2.pcap" &

xterm -title "VLAN2" -hold -e "sudo tcpreplay -l 5000000 -i enp1s0f1 ./udp_v2.pcap" &
xterm -title "VLAN3" -hold -e "sudo tcpreplay -l 5000000 -i enp1s0f1 ./udp_v3.pcap" &
xterm -title "VLAN2_1" -hold -e "sudo tcpreplay -l 5000000 -i enp1s0f1 ./udp_v2.pcap" &
END

### Notes:
# Pre-cache the pcap file (use -K), otherwise takes 10x time.
