#!/bin/bash

if ! source /rtr/functions.sh; then
    echo "Error: Could not load functions file"
    exit 1
fi

#debug flag
if [ "$DEBUG" = "true" ]; then
    set -x
fi

# wait for all node interfaces to come up
NODE_INTFS=`ip -o link show | grep -E 'eth[1-9][0-9]?[0-9]?@' | wc -l`
while (( $NODE_INTFS != $CLAB_INTFS ))  
do
  sleep 1
  NODE_INTFS=`ip -o link show | grep -P 'eth[1-9][0-9]?[0-9]?@' | wc -l`
done

check_node_intfs

readarray -t INTERFACES_ARRAY < <(ip -o link show | awk -F': ' '{print $2}' | sed 's/@.*//' | grep '^eth[1-9][0-9]*$' | sort -V)
INTERFACES_SPACE="${INTERFACES_ARRAY[*]}"
INTERFACES_SLASHES="/$(IFS=/; echo "${INTERFACES_ARRAY[*]}")/"


if [ ! -d "$CONF_DIR" ] ; then
  echo "Creating freeRtr run/* folders"
  mkdir -p $CONF_DIR $LOGS_DIR $PCAP_DIR $NTFW_DIR $MRT_DIR
fi

ip link show > $CONF_DIR/hwdet.eth
#cp /proc/tty/driver/serial $CONF_DIR/hwdet.ser
ip link show > $CONF_DIR/hwdet.mac

if [ ! -f "$SW_FILE" ] ; then
  cp $TRG/rtr-sw.txt $SW_FILE
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

initialize

# then trigger interfaces discovery
if [ "$FIRST_BOOT" = "true" ]; then
  echo "DATAPLANE_TYPE=$DATAPLANE_TYPE" > $CONF_DIR/.DATAPLANE_TYPE
  java -jar $TRG/rtr.jar test hwdet path $CONF_DIR/ iface pcap inline exclifc lo/tap20001/sit0/tunl0/eth0/gre0/erspan0/gretap0/ip6tnl0/veth0a/veth0b mem 1024m tcpvrf 2323 OOB 23
  if [ ! -f "$HW_FILE" ]; then
    cp $TRG/rtr-hw.txt $HW_FILE
  fi
  fix_interfaces
  chmod u+x $CONF_DIR/hwdet-*.sh
else
  if [ $DATAPLANE_STATUS_CODE -eq 0 ]; then
    echo "changed DATAPLANE_TYPE to pcapInt"
    prepare_pcapInt_sw_file
    java -jar $TRG/rtr.jar test hwdet path $CONF_DIR/ iface pcap inline exclifc lo/tap20001/sit0/tunl0/eth0/gre0/erspan0/gretap0/ip6tnl0/veth0a/veth0b/ mem 1024m tcpvrf 2323 OOB 23
    configure_interfaces_mac_sw_file
    delete_p4_server_sw_file
    delete_vrf_p4_sw_file
    fix_interfaces
  elif [ $DATAPLANE_STATUS_CODE -eq 1 ]; then
    echo "changed DATAPLANE_TYPE from pcapInt to p4"
    java -jar $TRG/rtr.jar test hwdet path $CONF_DIR/ iface pcap inline exclifc lo/tap20001/sit0/tunl0/eth0/gre0/erspan0/gretap0/ip6tnl0/veth0a/veth0b mem 1024m tcpvrf 2323 OOB 23
    fix_interfaces
  else
    echo "DATAPLANE_TYPE unchanged"
    if [ $NODE_INTFS_STATUS_CODE -eq 1 ] || [ $NODE_INTFS_STATUS_CODE -eq 0 ]; then
      prepare_pcapInt_sw_file
      java -jar $TRG/rtr.jar test hwdet path $CONF_DIR/ iface pcap inline exclifc lo/tap20001/sit0/tunl0/eth0/gre0/erspan0/gretap0/ip6tnl0/veth0a/veth0b mem 1024m tcpvrf 2323 OOB 23
      configure_interfaces_mac_sw_file
      delete_p4_server_sw_file
      delete_vrf_p4_sw_file
      fix_interfaces
    fi
  fi
fi

chmod u+x $CONF_DIR/hwdet-*.sh

exit 0