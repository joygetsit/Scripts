#!/bin/bash

# You should have set up ssh and configured passwordless ssh.
dur=(10 60 300)
pktsize=(50 100 500 1000 1470)
bw=(10K 1M 100M 500M 1000pps)
PacketSize=defaultgarbagevalue1
Duration=defaultgarbagevalue2
DurationX=$(($Duration + 5))
BandwidthTest=defaultgarbagevalue3
TestNo=1

for PacketSize in "${pktsize[@]}"; do
  for Duration in "${dur[@]}"; do
    for BandwidthTest in "${bw[@]}"; do
      for (( i = 1; i <= 3; i++ )); do
        DurationX=$(($Duration + 5))
        echo $PacketSize, $Duration, $DurationX, $BandwidthTest
        echo "Trial:"$i, "Test No.:"$TestNo
        ((TestNo=TestNo+1))
      done
    done
  done
done