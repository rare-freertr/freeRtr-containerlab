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

# default dataplane type
DATAPLANE_TYPE=${DATAPLANE_TYPE:-pcapInt}
# default vrf initialization
INIT_VRF=${INIT_VRF:-false}

# Function
initialize_pcapInt() {
  [ -L "$CONF_DIR/pcapInt.bin" ] || ln -s $TRG/pcapInt.bin $CONF_DIR/pcapInt.bin
}

initialize_p4emu() {
  [ -L "$CONF_DIR/pcapInt.bin" ] || ln -s $TRG/pcapInt.bin $CONF_DIR/pcapInt.bin
  [ -L "$CONF_DIR/p4emu.bin" ] || ln -s $TRG/p4emu.bin $CONF_DIR/p4emu.bin
  [ -L "$CONF_DIR/libp4emu_pcap.so" ] || ln -sf $TRG/libp4emu_pcap.so $CONF_DIR/libp4emu_pcap.so
  [ -L "$CONF_DIR/libp4emu_full.so" ] || ln -sf $TRG/libp4emu_full.so $CONF_DIR/libp4emu_full.so
}
prepare_p4emu_hw_file() {
HW_FILE_INSERT_AFTER_LINE="tcp2vrf 2323 OOB 23"
VETH_CPU_PORT_B=`cat /sys/class/net/eth0/address`
HW_FILE_LINES_TO_ADD=(
  "tcp2vrf 9080 p4 9080"
  "int eth0 eth ${VETH_CPU_PORT_B} 127.0.0.1 20001 127.0.0.1 20002"
  "proc cpu_port_0 $CONF_DIR/pcapInt.bin veth_cpu_port_b 20002 127.0.0.1 20001 127.0.0.1"
  "proc p4emu $CONF_DIR/p4emu.bin 127.0.0.1 9080 0 veth_cpu_port_a $INTERFACES_SPACE"
)

for (( idx=${#HW_FILE_LINES_TO_ADD[@]}-1 ; idx>=0 ; idx-- )) ; do
  line="${HW_FILE_LINES_TO_ADD[idx]}"
  if ! awk -v pat="$line" '$0 == pat { found=1 } END { exit !found }' "$HW_FILE"; then
    sed -i "/^${HW_FILE_INSERT_AFTER_LINE//\//\\/}\$/a $line" "$HW_FILE"
  fi
done
sed -i '$a\\' "$HW_FILE"
}
prepare_p4emu_sw_file() {
sed -i -E 's/ethernet([0-9]+)/sdn\1/g' "$SW_FILE"
sed -i -E 's/sdn0/ethernet0/g; s/sdn255/ethernet255/g' "$SW_FILE"
}
prepare_pcapInt_sw_file() {
sed -i -E 's/sdn([0-9]+)/ethernet\1/g' "$SW_FILE"
}
create_sdn_interfaces_sw_file() {
for INTF in "${INTERFACES_ARRAY[@]}"; do
  INTF_NUM=${INTF#eth}

  ed -s "$SW_FILE" <<EOF
/^interface sdn${INTF_NUM}\$/,/^!$/p
q
EOF

  if [ $? -ne 0 ]; then
    ed -s "$SW_FILE" <<EOC
\$a
interface sdn${INTF_NUM}
 exit
!
.
w
q
EOC
  fi
done
} 

delete_vrf_p4_sw_file() {
sed -i '/^vrf definition p4$/,/^!$/d' "$SW_FILE"
}

delete_p4_server_sw_file() {
sed -i '/^server p4lang p4$/,/^!$/d' "$SW_FILE"
}

create_vrf_p4_sw_file() {
if ! ed -s "$SW_FILE" <<'EOF'
/^vrf definition p4$/,/^ exit$/p
q
EOF
then
  ed -s "$SW_FILE" <<'EOC'
$a
vrf definition p4
 exit
.
w
q
EOC
fi
}

create_p4_server_sw_file() {
if ! ed -s "$SW_FILE" <<'EOF'
/^server p4lang p4$/,/^ exit$/p
q
EOF
then
  ed -s "$SW_FILE" <<'EOC'
$a
server p4lang p4
 interconnect ethernet0
 vrf p4
 exit
.
w
q
EOC
fi
}

export_ports_p4_server_interfaces_sw_file() {
for INTF in "${INTERFACES_ARRAY[@]}"; do
  INTF_NUM=${INTF#eth}
  EXPORT_PORT="export-port sdn${INTF_NUM} ${INTF_NUM} 1 0 0 0"
  ed -s "$SW_FILE" <<EOF
/^server p4lang p4\$/,/^ exit\$/g
  /$EXPORT_PORT/
  -1a
$EXPORT_PORT
.
w
q
EOF

done
}

create_vrf_core() {
  if ! ed -s "$SW_FILE" <<'EOF'
/^vrf definition CORE$/,/^ exit$/p
q
EOF
  then
    ed -s "$SW_FILE" <<'EOC'
$a
vrf definition CORE
 exit
.
w
q
EOC
  fi
}

add_export_vrf_to_p4server() {
  if ! grep -q "export-vrf CORE" "$SW_FILE"; then
    sed -i '/^ vrf p4$/a\ export-vrf CORE' "$SW_FILE"
  fi
}

add_vrf_forwarding_to_interfaces() {
  for INTF_TYPE in sdn ethernet; do
    EXCLUDE='ethernet0\|ethernet255'
    
    for INTF in $(grep -E "^interface ($INTF_TYPE)[0-9]+" "$SW_FILE" | grep -v "$EXCLUDE" | awk '{print $2}'); do
      if ! grep -A10 "^interface $INTF\$" "$SW_FILE" | grep -q "vrf forwarding CORE"; then
        sed -i "/^interface $INTF\$/a\ vrf forwarding CORE" "$SW_FILE"
      fi
    done
  done
}

add_export_bridges_to_p4server() {
  for BRIDGE_ID in $(grep -E "^bridge [0-9]+" "$SW_FILE" | awk '{print $2}'); do
    if ! grep -q "export-bridge $BRIDGE_ID" "$SW_FILE"; then
      if grep -q "export-vrf CORE" "$SW_FILE"; then
        sed -i "/^ export-vrf CORE$/a\ export-bridge $BRIDGE_ID" "$SW_FILE"
      else
        sed -i "/^ vrf p4$/a\ export-bridge $BRIDGE_ID" "$SW_FILE"
      fi
    fi
  done
}

configure_interfaces_mac_sw_file() {
for ((i=1; i<=NODE_INTFS; i++)); do
  mac=$(cat /sys/class/net/eth$i/address | tr -d ':')
  mac="${mac:0:4}.${mac:4:4}.${mac:8:4}"
  if [ "$DATAPLANE_TYPE" = "pcapInt" ]; then
    sed -i "/^interface ethernet$i\$/,/^ exit\$/s/^ macaddr .*/ macaddr $mac/" "$SW_FILE"
  elif [ "$DATAPLANE_TYPE" = "p4emu" ]; then
    sed -i "/^interface sdn$i\$/,/^ exit\$/s/^ macaddr .*/ macaddr $mac/" "$SW_FILE"
  fi
done
}


# wait for all node interfaces to come up
NODE_INTFS=`ip -o link show | grep -P 'eth[1-9]\d?@' | wc -l`
while (( $NODE_INTFS != $CLAB_INTFS ))  
do
  sleep 1
  NODE_INTFS=`ip -o link show | grep -P 'eth[1-9]\d?@' | wc -l`
done

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

if [ "$DATAPLANE_TYPE" = "p4emu" ]; then
  echo "Dataplane type is p4emu"

  ip link add veth_cpu_port_a type veth peer name veth_cpu_port_b
  ip link set veth_cpu_port_a up
  ip link set veth_cpu_port_b up

  ip link set veth_cpu_port_a promisc on
  ip link set veth_cpu_port_b promisc on

  ip link set dev veth_cpu_port_a up mtu 10240
  ip link set dev veth_cpu_port_b up mtu 10240

  TOE_OPTIONS="rx tx sg tso ufo gso gro lro rxvlan txvlan rxhash"
  for TOE_OPTION in $TOE_OPTIONS; do
    /sbin/ethtool --offload veth_cpu_port_a "$TOE_OPTION" off &> /dev/null
    /sbin/ethtool --offload veth_cpu_port_b "$TOE_OPTION" off &> /dev/null
    for i in $(ip -o link show | awk -F': ' '{print $2}' | sed 's/@.*//' | grep '^eth[0-9][0-9]*$'); do
      /sbin/ethtool --offload $i "$TOE_OPTION" off &> /dev/null
    done
  done

fi

if [ ! -f "$HW_FILE" ] ; then
  cp $TRG/rtr-sw.txt $SW_FILE
  cp $TRG/rtr-hw.txt $HW_FILE
  if [ "$DATAPLANE_TYPE" = "pcapInt" ]; then
    initialize_pcapInt
  elif [ "$DATAPLANE_TYPE" = "p4emu" ]; then
    initialize_p4emu
  fi
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
if [ "$DATAPLANE_TYPE" = "pcapInt" ]; then
  initialize_pcapInt
  prepare_pcapInt_sw_file
  java -jar $TRG/rtr.jar test hwdet path $CONF_DIR/ iface pcap inline exclifc lo/tap20001/sit0/tunl0/eth0/gre0/erspan0/gretap0/ip6tnl0 mem 1024m tcpvrf 2323 OOB 23
  configure_interfaces_mac_sw_file
  delete_p4_server_sw_file
  delete_vrf_p4_sw_file
elif [ "$DATAPLANE_TYPE" = "p4emu" ]; then
  initialize_p4emu
  java -jar $TRG/rtr.jar test hwdet path $CONF_DIR/ iface pcap inline exclifc lo/tap20001/sit0/tunl0/eth0/gre0/erspan0/gretap0/ip6tnl0/veth_cpu_port_a/veth_cpu_port_b$INTERFACES_SLASHES mem 1024m tcpvrf 2323 OOB 23
  prepare_p4emu_hw_file
  prepare_p4emu_sw_file
  create_sdn_interfaces_sw_file
  configure_interfaces_mac_sw_file
  create_vrf_p4_sw_file
  create_p4_server_sw_file
  export_ports_p4_server_interfaces_sw_file
fi

# default vrf initialization
if [ "$INIT_VRF" = "true" ]; then
  create_vrf_core
  if [ "$DATAPLANE_TYPE" = "p4emu" ]; then
    add_export_vrf_to_p4server
    add_export_bridges_to_p4server
  fi
  add_vrf_forwarding_to_interfaces
fi

chmod u+x $CONF_DIR/hwdet-*.sh

