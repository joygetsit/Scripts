from scapy.all import *
import sys, os

class nfptsheader(Packet):
    name = "nfptsheader"
    fields_desc = [
        BitField("ig_ts", 42, 32),
        BitField("eg_ts", 42, 32),
    ]
    def mysummary(self):
        return self.sprintf("ig_ts=%ig_ts%, eg_ts=%eg_ts%")

# bind_layers(Ether,MetadataHeader, type=0x2700)
# bind_layers(TimeStampHeader, IP)
