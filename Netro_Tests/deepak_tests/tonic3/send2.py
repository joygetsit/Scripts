#!/usr/bin/env python3
import argparse
import sys
import socket
import random
import struct

from scapy.all import *
#from metadataheader import MetadataHeader
import time


iface = get_if_list()[3]
print(get_if_list())
print(iface)



def main():
	print('pass 1 argument: <Number of packets>')

	for pktnum in range(int(sys.argv[1])):
		pkt = Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff', type=0x1600)
		pkt = pkt / Raw(load="JackSparrow")
		pkt.show2()
		print("_________________________________________________________________")
		sendp(pkt, iface=iface, verbose=True)
		time.sleep(1)


if __name__ == '__main__':
	main()
