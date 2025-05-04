#!/bin/bash

echo this script will install freeRtr dependencies on your computer.
echo WARNING: this can alter your current network settings!
echo prerequisites: minimal debian sid and root rights.

echo --------------------------------------------- installing $1...

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get -f -y dist-upgrade

apt install -f -y ca-certificates-java

PKG_LIST="apt-utils default-jre-headless socat ethtool iproute2 net-tools procps \
libpcap-dev openssl libssl-dev libbpf-dev bpftool \
zip unzip wget psmisc busybox \
telnet tshark nmap iperf vim ed"

apt-get -f -y --no-install-recommends install $PKG_LIST

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

