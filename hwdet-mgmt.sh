#!/bin/bash

# debug flag
set -x

# freeRtr base installation
# remove $TRG if you want to uninstall freeRtr
# This is the only adherence of freeRtr on the filesystem
TRG=/rtr
RUN_DIR=$TRG/run
CONF_DIR=$RUN_DIR/conf

# Detect eth0 network context allocated by Docker bridge
ETH0_MAC=`cat /sys/class/net/eth0/address`
ETH0_MACADDR=$(echo "$ETH0_MAC" | tr -d ':' | sed 's/\(....\)\(....\)\(....\)/\1.\2.\3/')
HOSTNAME=`hostname`
IPv4=$(hostname -i | awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {print $i; exit}}')
IPv6=$(hostname -i | awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9a-fA-F:]+$/) {print $i; exit}}')


HW_PENULTIMATE_LINE=`wc -l ${CONF_DIR}/rtr-hw.txt | awk '{print $1}'`

sed -i "${HW_PENULTIMATE_LINE}i\\
proc ifc255.sh ${CONF_DIR}/pcapInt.bin eth0 22552 127.0.0.1 22551 127.0.0.1\\
int eth255 eth ${ETH0_MAC} 127.0.0.1 22551 127.0.0.1 22552\
" $CONF_DIR/rtr-hw.txt

sed -i '${/^$/d;}' "$CONF_DIR/rtr-hw.txt"
sed -i '$a\\' "$CONF_DIR/rtr-sw.txt"

SW_PENULTIMATE_LINE=`wc -l ${CONF_DIR}/rtr-sw.txt | awk '{print $1}'`

sed -i "${SW_PENULTIMATE_LINE}i\\
hostname ${HOSTNAME}\\
interface ethernet255\\
 macaddr ${ETH0_MACADDR} \\
 vrf forwarding OOB\\
 ipv4 address ${IPv4} /24\\
 ipv6 address ${IPv6} /64\\
 no shutdown\\
 exit\\
do write\
" $CONF_DIR/rtr-sw.txt

# flush docker eth0 config 
# so that freeRtr management connectivity 
# will take precedence over Linux container 
ip addr flush dev eth0

exit 0

