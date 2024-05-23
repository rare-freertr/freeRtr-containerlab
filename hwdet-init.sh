#!/bin/bash

#debug flag
set -x

TRG=/rtr
RUN_DIR=$TRG/run
CONF_DIR=$RUN_DIR/conf
LOGS_DIR=$RUN_DIR/logs
PCAP_DIR=$RUN_DIR/pcap
NTFW_DIR=$RUN_DIR/ntfw
MRT_DIR=$RUN_DIR/mrt
HW_FILE=$CONF_DIR/rtr-hw.txt
SW_FILE=$CONF_DIR/rtr-sw.txt

# wait for all node interfaces to come up
NODE_INTFS=`ip -o link show | grep -P 'eth[1-9]\d?@' | wc -l`
while (( $NODE_INTFS != $CLAB_INTFS ))  
do
  sleep 1
  NODE_INTFS=`ip -o link show | grep -P 'eth[1-9]\d?@' | wc -l`
done

if [ ! -d "$CONF_DIR" ] ; then
  echo "Creating freeRtr run/* folders"
  mkdir -p $CONF_DIR $LOGS_DIR $PCAP_DIR $NTFW_DIR $MRT_DIR
fi

cp /proc/net/dev $CONF_DIR/hwdet.eth
cp /proc/tty/driver/serial $CONF_DIR/hwdet.ser
ip link show > $CONF_DIR/hwdet.mac

if [ ! -f "$HW_FILE" ] ; then
  cp $TRG/rtr-sw.txt $SW_FILE
  cp $TRG/rtr-hw.txt $HW_FILE
  ln -s $TRG/pcapInt.bin $CONF_DIR/pcapInt.bin
fi

if [ -f "$CONF_DIR/hwdet-all.sh" ] ; then
  echo "$CONF_DIR/hwdet-all.sh already exist ..."
  echo "Saving previous session $CONF_DIR/hwdet-all.sh to $CONF_DIR/hwdet-all.sh.bak"
  mv $CONF_DIR/hwdet-all.sh $CONF_DIR/hwdet-all.sh.bak
fi

if [ -f "$CONF_DIR/hwdet-main.sh" ] ; then
  echo "$CONF_DIR/hwdet-main.sh already exist ..."
  echo "Renaming $CONF_DIR/hwdet-main.sh to $CONF_DIR/hwdet-main.sh.bak"
  mv $CONF_DIR/hwdet-main.sh $CONF_DIR/hwdet-main.sh.bak
fi


# then trigger interfaces discovery
java -jar $TRG/rtr.jar test hwdet path $CONF_DIR/ iface pcap inline exclifc lo/tap20001/sit0/tunl0/eth0/gre0/erspan0/gretap0/ip6tnl0 mem 1024m tcpvrf 2323 OOB 23
chmod u+x $CONF_DIR/hwdet-*.sh

