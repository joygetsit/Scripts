from scapy.all import *
import sys, os
from nfp_ts_hdr import nfptsheader

class MetadataHeader(Packet):
    name = "MetadataHeader"
    fields_desc = [
        BitField("packet_length", 42, 16),
        BitField("ingress_port", 42, 16),
        BitField("egress_port", 42, 16)
    ]
    def mysummary(self):
        return self.sprintf("packet_length=%packet_length%, ingress_port=%ingress_port%, egress_port=%egress_port%")

bind_layers(Ether,nfptsheader, type=0x2700)
bind_layers(nfptsheader,MetadataHeader)
# bind_layers(TimeStampHeader, IP)
