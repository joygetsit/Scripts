#!/bin/bash

# Author: Deepak Choudhary
# Date: April 2023
# Description: Flush Global Cache and add ARP entry

sysctl net.ipv4.neigh.enp1s0f0.gc_stale_time=0
arp -s 10.0.0.2 90:e2:ba:e2:25:f9
