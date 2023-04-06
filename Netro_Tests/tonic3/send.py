#!/usr/bin/env python3
import argparse
import sys
import socket
import random
import struct

from scapy.all import sendp, send, get_if_list, get_if_hwaddr
from scapy.all import Packet
from scapy.all import Ether, IP, UDP, TCP
from scapy.all import *
from metadataheader import MetadataHeader
import time


def get_if(interface):
    iface = None  # "h1-eth0"
    for i in get_if_list():
        if interface in i:
            iface = i
            break
    if not iface:
        print("Cannot find interface ", interface)
        exit(1)
    return iface


def main():
    if len(sys.argv) < 5:
        print('pass 4 arguments: <destination> <message> <Number of packets> <interval in seconds>')
        exit(1)

    iface = get_if(sys.argv[1])

    for pktnum in range(int(sys.argv[3])):
        print("\nSending on interface %s; Packet %d" % (iface, (pktnum + 1)))
        Content_data = sys.argv[2] + " Packet Number " + str(pktnum + 1)
        pkt = Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff', type=0x2700)
        # pkt = pkt / MetadataHeader() / Raw(load=Content_data)
        pkt = pkt / Raw(load=Content_data)
        pkt.show2()
        print("_________________________________________________________________")
        sendp(pkt, iface=iface, verbose=False)
        time.sleep(float(sys.argv[4]))  # Wait sys.argv[4] seconds


if __name__ == '__main__':
    main()
