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
# eth0 02:42:ac:14:14:09 #
# eth1 aa:c1:ab:76:8c:81 #
# eth2 aa:c1:ab:c6:21:1b #
# eth3 aa:c1:ab:c8:dd:8b #
# eth4 aa:c1:ab:28:64:c9 #

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
ip link set eth3 up multicast on promisc on mtu 1500
ethtool -K eth3 rx off
ethtool -K eth3 tx off
ethtool -K eth3 sg off
ethtool -K eth3 tso off
ethtool -K eth3 ufo off
ethtool -K eth3 gso off
ethtool -K eth3 gro off
ethtool -K eth3 lro off
ethtool -K eth3 rxvlan off
ethtool -K eth3 txvlan off
ethtool -K eth3 ntuple off
ethtool -K eth3 rxhash off
ethtool --set-eee eth3 eee off
ip link set eth4 up multicast on promisc on mtu 1500
ethtool -K eth4 rx off
ethtool -K eth4 tx off
ethtool -K eth4 sg off
ethtool -K eth4 tso off
ethtool -K eth4 ufo off
ethtool -K eth4 gso off
ethtool -K eth4 gro off
ethtool -K eth4 lro off
ethtool -K eth4 rxvlan off
ethtool -K eth4 txvlan off
ethtool -K eth4 ntuple off
ethtool -K eth4 rxhash off
ethtool --set-eee eth4 eee off

### lines ###
echo starting lines.

### main ###
echo starting main.
start-stop-daemon -S -b -x /rtr/run/conf/hwdet-main.sh
exit 0
