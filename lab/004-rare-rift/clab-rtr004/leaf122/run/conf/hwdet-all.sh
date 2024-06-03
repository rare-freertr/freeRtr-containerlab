#!/bin/sh

cd /rtr/run/conf/
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6
echo 0 > /proc/sys/net/ipv6/conf/lo/disable_ipv6
ip link set lo up mtu 65535
ip addr add 127.0.0.1/8 dev lo
ip addr add ::1/128 dev lo
ulimit -c unlimited
#modprobe -r kvm_intel
#modprobe kvm_intel nested=1
#echo 1 > /sys/kernel/mm/ksm/run

### macs ###
echo starting macs.
# eth0 02:42:ac:14:14:06 #
# eth1 aa:c1:ab:d1:28:83 #
# eth2 aa:c1:ab:35:a2:0f #

### interfaces ###
echo starting interfaces.
ip link set eth1 up multicast on promisc on mtu 1500
ethtool -K eth1 rx off
ethtool -K eth1 tx off
ethtool -K eth1 sg off
ethtool -K eth1 tso off
ethtool -K eth1 ufo off
ethtool -K eth1 gso off
ethtool -K eth1 gro off
ethtool -K eth1 lro off
ethtool -K eth1 rxvlan off
ethtool -K eth1 txvlan off
ethtool -K eth1 ntuple off
ethtool -K eth1 rxhash off
ethtool --set-eee eth1 eee off
ip link set eth2 up multicast on promisc on mtu 1500
ethtool -K eth2 rx off
ethtool -K eth2 tx off
ethtool -K eth2 sg off
ethtool -K eth2 tso off
ethtool -K eth2 ufo off
ethtool -K eth2 gso off
ethtool -K eth2 gro off
ethtool -K eth2 lro off
ethtool -K eth2 rxvlan off
ethtool -K eth2 txvlan off
ethtool -K eth2 ntuple off
ethtool -K eth2 rxhash off
ethtool --set-eee eth2 eee off

### lines ###
echo starting lines.

### main ###
echo starting main.
start-stop-daemon -S -b -x /rtr/run/conf/hwdet-main.sh
exit 0
