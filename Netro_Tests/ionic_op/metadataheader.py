from scapy.all import *
import sys, os

TYPE_MetaData = 0x2700
# TYPE_IPV4 = 0x0800

class MetadataHeader(Packet):
    name = "MetadataHeader"
    fields_desc = [
        BitField("X", 0, 32),
        BitField("Y", 0, 32),
        BitField("Z", 0, 32),
        BitField("B1", 0, 32),
        BitField("B2", 0, 32),
        BitField("F1", 0, 32),
        BitField("F2", 0, 32),
        BitField("F3", 0, 32)
    ]
    def mysummary(self):
        return self.sprintf("P1=%P1%, P2=%P2%, P3=%P3%, P4=%P4%")

bind_layers(Ether, MetadataHeader, type=TYPE_MetaData)
