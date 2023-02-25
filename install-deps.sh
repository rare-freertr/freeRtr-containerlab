#!/bin/bash

echo this script will install freeRtr dependencies on your computer.
echo WARNING: this can alter your current network settings!
echo prerequisites: minimal debian sid and root rights.

installPackage()
{
echo ""
echo ""
echo ""
echo ""
echo --------------------------------------------- installing $1...
apt-get -f -y install $1
}

apt-get update
apt-get -f -y dist-upgrade

PKG_LIST="default-jre-headless socat ethtool iproute2 net-tools procps \
libpcap-dev openssl libssl-dev libbpf-dev bpftool \
zip unzip wget psmisc busybox \
telnet tshark nmap iperf"

apt-get -f -y install $PKG_LIST

#for PKG in $PKG_LIST ; do
#  installPackage $PKG
#done

: << 'COMMENT'
for PKG in default-jre-headless socat ethtool iproute2 net-tools procps ; do
  installPackage $PKG
  done

for PKG in libpcap-dev openssl libssl-dev libbpf-dev bpftool ; do
  installPackage $PKG
  done

for PKG in zip unzip wget psmisc busybox; do
  installPackage $PKG
  done

for PKG in telnet tshark nmap iperf; do
  installPackage $PKG
  done
COMMENT

for PKG in apparmor cloudinit; do
  echo ""
  echo ""
  echo ""
  echo ""
  echo --------------------------------------------- removing $1...
  apt-get -f -y remove $1
  done

sync

echo freeRtr dependencies installation finished! 

