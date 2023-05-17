from scapy.all import *
import sys, os
from nfp_ts_hdr import nfptsheader

class MetadataHeader(Packet):
    name = "MetadataHeader"
    fields_desc = [
        BitField("ing_glb_tstamp", 42, 64),
        BitField("cur_glb_tstamp", 42, 64),
        BitField("pkt_len", 42, 14),
        BitField("ig_port", 42, 16),
        BitField("eg_port", 42, 16),
        BitField("dummy", 0, 2)
    ]
    def mysummary(self):
        return self.sprintf("ingress=%ingress%, egress=%egress%")

bind_layers(Ether,nfptsheader, type=0x2700)
bind_layers(nfptsheader,MetadataHeader)
# bind_layers(TimeStampHeader, IP)
