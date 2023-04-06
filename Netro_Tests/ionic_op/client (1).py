#!/usr/bin/env python3
import sys
import socket, netifaces
from scapy.all import *
from scapy.all import Ether, IP, TCP, UDP, Raw

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
    server_ip = sys.argv[2]
    # ip address and interface of client
    iface = get_if(sys.argv[1])
    src_ip = netifaces.ifaddresses(iface)[netifaces.AF_INET][0]['addr']
    port = 60000
    buffer_size = 2048
    # bind socket to client at port 60000
    s.bind((src_ip, port))
    s.connect((server_ip, 60000))
    print("connected successfully")
    data=s.recv(buffer_size)
    print(data)
    i=0
    while i<10:
        message='\0' * 10+str(i)
        s.send(message.encode())
        data=s.recv(buffer_size)
        print(data)
        i+=1

main()