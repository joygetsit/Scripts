from scapy.all import *
import sys, os

class nfptsheader(Packet):
    name = "nfptsheader"
    fields_desc = [
        BitField("mac_ig_ts", 42, 32),
        BitField("mac_eg_ts", 42, 32),
        BitField("me_ig_ts", 42, 64),
        BitField("me_eg_ts", 42, 64),
        BitField("packet_length", 42, 16),
        BitField("ingress_port", 42, 16),
        BitField("egress_port", 42, 16),
        BitField("mac_eg_ts_zero", 0, 24),
        BitField("mac_eg_ts_off_byte", 0, 8)
    ]
    def mysummary(self):
        return self.sprintf("mac_ig_ts=%mac_ig_ts%, mac_eg_ts=%mac_eg_ts%, me_ig_ts=%me_ig_ts%, me_eg_ts=%me_eg_ts%, packet_length=%packet_length%, ingress_port=%ingress_port%, egress_port=%egress_port%, mac_eg_ts_zero=%mac_eg_ts_zero%, mac_eg_ts_off_byte=%mac_eg_ts_off_byte%")

# bind_layers(Ether,MetadataHeader, type=0x2700)
# bind_layers(TimeStampHeader, IP)