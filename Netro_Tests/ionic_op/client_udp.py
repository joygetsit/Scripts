# Author: Soumya Kanta Rana and Deepak Choudhary
# Date: 10 April 2023
# Description: UDP Client Program for ionic program (updates udp checksum with payload)

import socket
import time, random, csv
 
serverAddressPort   = ("10.0.0.2", 1234)
bufferSize          = 2808
# Create a UDP socket at client side
UDPClientSocket = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
#UDPClientSocket.setblocking(0)
#msgFromClient       = "Hello UDP Server"
#bytesToSend         = str.encode(msgFromClient)
clientAddressPort   = ("10.0.0.1", random.randint(10000,65535))
UDPClientSocket.bind(clientAddressPort)
message="abcdefghijklmnopqraabcdefghijklmnopqrabcdefghijklmnopqrabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrabcdefghijklmnopqrabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrabcdefghijklmnopqrabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrabcdefghijklmnopqrabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrabcdefghijklmnopqrabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrabcdefghijklmnopqrabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrabcdefghijklmnopqrabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrabcdefghijklmnopqrabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrabcdefghijklmnopqrabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrstuvwabcdefghijklmnopqrabcdefghijklmnopqrabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrabcdefghijklmnopqrabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrabcdefghijklmnopqrabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrabcdefghijklmnopqrabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrstuvwxystuvwxyxystuvwxybcdefghijklmnopqrabcdefghijklmnopqrstuvwxystuvwxyabcdefghijklmnopqrstuvwxystuvwxy" 
packets=[]
#while(True):
    #bytesAddressPair = UDPClientSocket.recvfrom(bufferSize) 
    #print(bytesAddressPair[0])
    #break
i=0
while i<65536*2:
    msgFromClient = i.to_bytes(4,'big')
    bytesToSend = msgFromClient+str.encode(message)
    # try:
    temp=UDPClientSocket.sendto(bytesToSend, socket.MSG_DONTWAIT, serverAddressPort)
    # UDPClientSocket.flush()
    print(i,temp)
    packets.append([i])
    time.sleep(0.001)
    bytesToSend=b''
    # except:
    #     UDPClientSocket.close()
    #     print("unknown error! socket gets stuck")
        # exit()
    i+=1

# filename="run_5_src.csv"
# with open(filename, 'w') as csvfile:
    # csvwriter = csv.writer(csvfile)
    # csvwriter.writerows(packets)
UDPClientSocket.close()
