#!/bin/bash

# freeRtr base installation
# remove $TRG if you want to uninstall freeRtr
# This is the only adherence of freeRtr on the filesystem
TRG=/rtr

# Detect eth0 network context allocated by Docker bridge

ETH0_MAC=`cat /sys/class/net/eth0/address`
HOSTNAME=`hostname`
IPv4=`hostname -i | awk '{print $2}'`
IPv6=`hostname -i | awk '{print $1}'`

# Identify the end of freeRtr hw|sw file

HW_PENULTIMATE_LINE=`wc -l /rtr/rtr-hw.txt | awk '{print $1}'`
SW_PENULTIMATE_LINE=`wc -l /rtr/rtr-sw.txt | awk '{print $1}'`

# Insert management interface information
# to rtr-hw.txt
# And set it to ethernet255 
# (Arbitrary choice ! Please change it if it bothers you !)

sed -i "${HW_PENULTIMATE_LINE}i\\
proc ifc255.sh /rtr/pcapInt.bin eth0 22552 127.0.0.1 22551 127.0.0.1\\
int eth255 eth ${ETH0_MAC} 127.0.0.1 22551 127.0.0.1 22552\
" $TRG/rtr-hw.txt

# Insert management interface information
# to rtr-sw.txt

sed -i "${SW_PENULTIMATE_LINE}i\\
hostname ${HOSTNAME}\\
interface ethernet255\\
 vrf forwarding OOB\\
 ipv4 address ${IPv4} /24\\
 ipv6 address ${IPv6} /64\\
 no shutdown\\
 exit\\
do write\
" $TRG/rtr-sw.txt

exit 0

