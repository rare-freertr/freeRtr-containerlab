#!/bin/bash

TRG=/rtr

cp /proc/net/dev $TRG/hwdet.eth
cp /proc/tty/driver/serial $TRG/hwdet.ser
ip link show > $TRG/hwdet.mac

if [ -f "$TRG/rtr-hw.txt" ] ; then
  echo "$TRG/rtr-hw.txt already exist ..."
  echo "Renaming $TRG/rtr-hw.txt to $TRG/rtr-hw.bak"
  mv $TRG/rtr-hw.txt $TRG/rtr-hw.txt.bak
fi

if [ -f "$TRG/hwdet-all.sh.txt" ] ; then
  echo "$TRG/hwdet-all.sh already exist ..."
  echo "Renaming $TRG/hwdet-all.sh to /hwdet-all.sh.bak"
  mv $TRG/hwdet-all.sh $TRG/hwdet-all.sh.bak
fi

if [ -f "$TRG/hwdet-main.sh.txt" ] ; then
  echo "$TRG/hwdet-main.sh already exist ..."
  echo "Renaming $TRG/hwdet-main.sh to /hwdet-main.sh.bak"
  mv $TRG/hwdet-main.sh $TRG/hwdet-main.sh.bak
fi

java -jar $TRG/rtr.jar test hwdet path $TRG/ iface pcap inline exclifc lo/tap20001/sit0/tunl0/eth0 mem 1024m tcpvrf 2323 OOB 23
chmod u+x $TRG/hwdet-*.sh

