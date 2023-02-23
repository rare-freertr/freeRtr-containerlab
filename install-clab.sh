#!/bin/sh

TRG=$1
TMP=/root/install.rtr

if [ -z "$TRG" ] ; then
  echo "usage: install-clab.sh <target directory>"
  exit
  fi

echo configuring freeRtr to $TRG directory

echo net.ipv6.conf.all.disable_ipv6=1 > /etc/sysctl.d/disableipv6.conf
echo net.ipv6.conf.default.disable_ipv6=1 >> /etc/sysctl.d/disableipv6.conf
echo kernel.panic=10 > /etc/sysctl.d/panic.conf

mkdir -p $TRG
cp $TMP/src/rtr.jar $TRG/
cp $TMP/src/rtr.ver $TRG/
cp $TMP/binTmp/*.bin $TRG/
cp /proc/net/dev $TRG/hwdet.eth
cp /proc/tty/driver/serial $TRG/hwdet.ser
ip link show > $TRG/hwdet.mac
java -jar $TRG/rtr.jar test hwdet path $TRG/ iface pcap inline exclifc lo/tap20001/sit0/tunl0/eth0 mem 1024m tcpvrf 2323 OOB 23
chmod 755 $TRG/*.sh
ls -l $TRG/

