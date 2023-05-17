#!/home/zenlab/Documents/Networking_Experiments/Scripts/venv/bin/python3
import sys
import struct
import os

from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr
from scapy.all import Packet, IPOption
from scapy.all import ShortField, IntField, LongField, BitField, FieldListField, FieldLenField
from scapy.all import IP, TCP, UDP, Raw
from scapy.layers.inet import _IPOption_HDR
from metadataheader import MetadataHeader
from nfp_ts_hdr import nfptsheader
import time


def get_if(interface):
    ifs = get_if_list()
    iface = None
    for i in get_if_list():
        if interface in i:
            iface = i
            break;
    if not iface:
        print("Cannot find interface")
        exit(1)
    return iface


class IPOption_MRI(IPOption):
    name = "MRI"
    option = 31
    fields_desc = [_IPOption_HDR,
                   FieldLenField("length", None, fmt="B",
                                 length_of="swids",
                                 adjust=lambda pkt, l: l + 4),
                   ShortField("count", 0),
                   FieldListField("swids",
                                  [],
                                  IntField("", 0),
                                  length_from=lambda pkt: pkt.count * 4)]


def handle_pkt(pkt):
    if nfptsheader in pkt:
        print("\nGot_a_packet:")
        pkt.show2()
        sys.stdout.flush()
        print("_________________________________________________")


def main():
    bind_layers(Ether, nfptsheader, type=0x2700)
    iface = get_if(sys.argv[1])
    print("sniffing on %s" % iface)
    sys.stdout.flush()
    sniff(iface=iface,
          prn=lambda x: handle_pkt(x))


if __name__ == '__main__':
    main()
