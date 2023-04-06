import sys
import socket, netifaces
from scapy.all import *
from scapy.all import Ether, IP, TCP, UDP, Raw

class MetadataHeader(Packet):
    name = "MetadataHeader"
    fields_desc = [
        BitField("timestamp", 0, 64),
        BitField("signal_strength", 0, 16)
    ]
    def mysummary(self):
        return self.sprintf("metadata")

def get_if(interface):
    ifs=get_if_list()
    iface=None 
    for i in get_if_list():
        if interface in i:
            iface=i
            break
    if not iface:
        print("Cannot find "+interface+ " interface")
        exit(1)
    return iface

def main():
    s=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    # ip address of server
    ip = sys.argv[1]      
    fid=open("data.txt", 'w')
    port = 60000
    j=0
    buffer_size = 2048
    # bind socket to server at port 60000
    s.bind((ip, port))
    s.listen(5)
    while True:
        c, addr = s.accept()
        print ('Got connection from', addr )
        c.send('Thank you for connecting'.encode())
        i=0
        while True:
            try:
                data=c.recv(buffer_size)
                msg='\0' * 10+"ack "+str(i)
                c.send(msg.encode())
                if data != b'':
                    #j+=int(data.decode())
                    print(data)
                i+=1
            except KeyboardInterrupt:
                c.close()
                fid.close()
                print(j)
                s.shutdown(socket.SHUT_RDWR)
                s.close()
                print("socket closed")
                exit()
            except:
                c.close()
                fid.close()
                s.shutdown(socket.SHUT_RDWR)
                s.close()
                print("socket closed")
                exit()

main()