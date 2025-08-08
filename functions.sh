#!/bin/bash
# functions.sh


# global vars
TRG=/rtr
RUN_DIR=$TRG/run
CONF_DIR=$RUN_DIR/conf
LOGS_DIR=$RUN_DIR/logs
PCAP_DIR=$RUN_DIR/pcap
NTFW_DIR=$RUN_DIR/ntfw
MRT_DIR=$RUN_DIR/mrt
HW_FILE=$CONF_DIR/rtr-hw.txt
SW_FILE=$CONF_DIR/rtr-sw.txt

#
#DEBUG=${DEBUG:-false}
FIRST_BOOT=${FIRST_BOOT:-false}
# default dataplane type
DATAPLANE_TYPE=${DATAPLANE_TYPE:-pcapInt}
# default vrf initialization
INIT_VRF=${INIT_VRF:-false}

: ${DATAPLANE_CHANGED_TO_PCAPINT:=false}
: ${DATAPLANE_CHANGED_FROM_PCAPINT:=false}
: ${DATAPLANE_STATUS_CODE:=2}
: ${NODE_INTFS_PREVIOUS:=0}
: ${NODE_INTFS_CHANGED:=false}
: ${NODE_INTFS_STATUS_CODE:=1}



# Detect eth0 network context allocated by Docker bridge
MGMT_INTERFACE_MAC_ADDRESS=`cat /sys/class/net/eth0/address`
MGMT_MAC_ADDRESS=$(echo "$MGMT_INTERFACE_MAC_ADDRESS" | tr -d ':' | sed 's/\(....\)\(....\)\(....\)/\1.\2.\3/')
HOSTNAME=`hostname`
IPv4=$(hostname -i | awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {print $i; exit}}')
IPv6=$(hostname -i | awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9a-fA-F:]+$/) {print $i; exit}}')

first_boot() {
    BOOT_MARKER="/rtr/run/conf/.bootmarker"
    if [ ! -f "$BOOT_MARKER" ]; then
        export FIRST_BOOT=true
        mkdir -p "$(dirname "$BOOT_MARKER")"
        touch "$BOOT_MARKER"
        echo "first boot detected"
    fi
}

initialize() {
  [ -d "$CONF_DIR" ] || mkdir -p "$CONF_DIR"
  for file in /rtr/*.bin /rtr/*.so; do
        [ -e "$file" ] || continue
        
        filename=$(basename "$file")
        
        [ -L "$CONF_DIR/$filename" ] || ln -sf "$file" "$CONF_DIR/$filename"
    done

  
  # initialize p4 interconnect (CPU PORT)

  ip link add veth0a type veth peer name veth0b
  ip link set veth0a up
  ip link set veth0b up

  ip link set veth0a promisc on
  ip link set veth0b promisc on

  ip link set dev veth0a up mtu 10240
  ip link set dev veth0b up mtu 10240

  TOE_OPTIONS="rx tx sg tso ufo gso gro lro rxvlan txvlan rxhash"
  for TOE_OPTION in $TOE_OPTIONS; do
    /sbin/ethtool --offload veth0a "$TOE_OPTION" off &> /dev/null
    /sbin/ethtool --offload veth0b "$TOE_OPTION" off &> /dev/null
    for i in $(ip -o link show | awk -F': ' '{print $2}' | sed 's/@.*//' | grep '^eth[0-9][0-9]*$'); do
      /sbin/ethtool --offload $i "$TOE_OPTION" off &> /dev/null
    done
  done
}

configure_hw_file() {
sed -i "${HW_PENULTIMATE_LINE}i\\
proc ifc255.sh ${CONF_DIR}/pcapInt.bin eth0 22552 127.0.0.1 22551 127.0.0.1\\
int eth255 eth ${MGMT_INTERFACE_MAC_ADDRESS} 127.0.0.1 22551 127.0.0.1 22552\
" $CONF_DIR/rtr-hw.txt

sed -i '${/^$/d;}' "$CONF_DIR/rtr-hw.txt"
sed -i '$a\\' "$CONF_DIR/rtr-sw.txt"
}

configure_mgmt_eth255() {
sed -i "${SW_PENULTIMATE_LINE}i\\
hostname ${HOSTNAME}\\
interface eth255\\
 macaddr ${MGMT_MAC_ADDRESS} \\
 description OOB \\
 vrf forwarding OOB\\
 ipv4 address ${IPv4} /24\\
 ipv6 address ${IPv6} /64\\
 no shutdown\\
 exit\
" $CONF_DIR/rtr-sw.txt
}

initialize_rtr() {
  echo "do write" >> $CONF_DIR/rtr-sw.txt
  echo "do reload force" >> $CONF_DIR/rtr-sw.txt
  java -jar $TRG/rtr.jar routerc $CONF_DIR/rtr- > /dev/null
}

prepare_pcapInt_sw_file() {
    sed -i -E 's/sdn([0-9]+)/ethernet\1/g' "$SW_FILE"
}

delete_vrf_p4_sw_file() {
sed -i '/^vrf definition p4$/,/^!$/d' "$SW_FILE"
}

delete_p4_server_sw_file() {
sed -i '/^server p4lang p4$/,/^!$/d' "$SW_FILE"
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

add_vrf_forwarding_to_interfaces() {
  # Configuration file
  local config_file="$SW_FILE"
  local temp_file=$(mktemp)
  
  # Process the file line by line
  while IFS= read -r line; do
    # Write current line to temp file
    echo "$line" >> "$temp_file"
    
    # Check if this is an interface line that needs VRF forwarding
    if [[ "$line" =~ ^interface\ (ethernet|sdn)([0-9]+)$ ]]; then
      interface_name="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
      
      # Skip excluded interfaces
      if [ "$interface_name" = "ethernet0" ] || [ "$interface_name" = "ethernet255" ] || [ "$interface_name" = "sdn255" ]; then
        continue
      fi
      
      # Extract interface block to check if VRF already exists
      # We use the original file for this check
      interface_block=$(sed -n "/^$line$/,/^ exit/p" "$config_file")
      
      # If VRF not present, add it
      if ! echo "$interface_block" | grep -q "vrf forwarding CORE"; then
        echo " vrf forwarding CORE" >> "$temp_file"
        if [ "$DEBUG" = "true" ]; then
            echo "Adding VRF CORE to interface $interface_name"
        fi
      fi
    fi
  done < "$config_file"
  
  # Replace original file with modified version
  mv "$temp_file" "$config_file"
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

remove_p4_telnet() {
  sed -i '/^tcp2vrf 2323 p4 23 127\.0\.0\.1$/d' $HW_FILE
  perl -0777 -i -pe 's/\!\nserver telnet p4\n.*?exit\n\!//s' $SW_FILE
}

fix_interfaces() {
  perl -i.bak -pe 's/^(proc ifc(\d+)\.sh .+?) eth\d+/\1 eth$2/g unless /^proc ifc255\.sh/' $HW_FILE
}

check_dataplane_type() {
    local boot_config="$CONF_DIR/.DATAPLANE_TYPE"
    local current_type="${DATAPLANE_TYPE}"
    local stored_type=""
    
    DATAPLANE_CHANGED_TO_PCAPINT=false
    DATAPLANE_CHANGED_FROM_PCAPINT=false
    DATAPLANE_STATUS_CODE=2
    
    # Check if DATAPLANE_TYPE is set
    if [ -z "$current_type" ]; then
        if [ "$DEBUG" = "true" ]; then
          echo "Error: DATAPLANE_TYPE environment variable is not set"
        fi
        DATAPLANE_STATUS_CODE=3
        return 3
    fi
    
    # Create directory structure
    mkdir -p "$(dirname "$boot_config")" || {
        if [ "$DEBUG" = "true" ]; then
          echo "Failed to create directory structure for $boot_config"
        fi
        DATAPLANE_STATUS_CODE=3
        return 3
    }
    
    # Check if boot config file exists and read from it
    if [ -f "$boot_config" ]; then
        # Read stored dataplane type
        stored_type=$(grep "^DATAPLANE_TYPE=" "$boot_config" | cut -d'=' -f2)
        
        # Check if dataplane type has changed
        if [ "$stored_type" != "$current_type" ]; then
            if [ "$current_type" = "pcapInt" ]; then
                if [ "$DEBUG" = "true" ]; then
                  echo "Dataplane type has changed to pcapInt: $stored_type -> $current_type"
                fi
                DATAPLANE_CHANGED_TO_PCAPINT=true
                DATAPLANE_STATUS_CODE=0
            elif [ "$stored_type" = "pcapInt" ]; then
                if [ "$DEBUG" = "true" ]; then
                  echo "Dataplane type has changed from pcapInt: $stored_type -> $current_type"
                fi
                DATAPLANE_CHANGED_FROM_PCAPINT=true
                DATAPLANE_STATUS_CODE=1
            else
                if [ "$DEBUG" = "true" ]; then
                  echo "Dataplane type has changed (not pcapInt related): $stored_type -> $current_type"
                fi
            fi
        else
            if [ "$DEBUG" = "true" ]; then
              echo "Dataplane type unchanged: $current_type"
            fi
        fi
    else
        # No previous configuration found
        if [ "$current_type" = "pcapInt" ]; then
            if [ "$DEBUG" = "true" ]; then
              echo "Initial dataplane type is pcapInt"
            fi
            DATAPLANE_CHANGED_TO_PCAPINT=true
            DATAPLANE_STATUS_CODE=0
        else
            if [ "$DEBUG" = "true" ]; then
              echo "Initial dataplane type (not pcapInt): $current_type"
            fi
        fi
    fi
    
    # Always update the file with current value
    echo "DATAPLANE_TYPE=$current_type" > "$boot_config" || {
      if [ "$DEBUG" = "true" ]; then
        echo "Failed to write to $boot_config"
      fi
      DATAPLANE_STATUS_CODE=3
      return 3
    }
    export DATAPLANE_CHANGED_TO_PCAPINT
    export DATAPLANE_CHANGED_FROM_PCAPINT
    export DATAPLANE_STATUS_CODE
    return $DATAPLANE_STATUS_CODE
}

check_node_intfs() {
    local node_intfs_config="$CONF_DIR/.node_intfs"
    local current_intfs="${NODE_INTFS}"
    local previous_stored_intfs=""
    
    # Reset global variables
    NODE_INTFS_CHANGED=false
    NODE_INTFS_PREVIOUS=0
    NODE_INTFS_STATUS_CODE=1
    
    # Check if NODE_INTFS is set
    if [ -z "$current_intfs" ]; then
        if [ "$DEBUG" = "true" ]; then
          echo "Error: NODE_INTFS variable is not set"
        fi
        NODE_INTFS_STATUS_CODE=2  # Error code
        return 2
    fi
    
    # Create directory structure if needed
    mkdir -p "$(dirname "$node_intfs_config")" || {
        if [ "$DEBUG" = "true" ]; then
          echo "Failed to create directory structure for $node_intfs_config"
        fi
        NODE_INTFS_STATUS_CODE=2
        return 2
    }
    
    # Check if configuration file exists and read from it
    if [ -f "$node_intfs_config" ]; then
        # Read stored value
        previous_stored_intfs=$(cat "$node_intfs_config" 2>/dev/null)
        
        # Check if count has changed
        if [ "$previous_stored_intfs" != "$current_intfs" ]; then
            if [ "$DEBUG" = "true" ]; then
              echo "Node interfaces count has changed: $previous_stored_intfs -> $current_intfs"
            fi
            NODE_INTFS_CHANGED=true
            NODE_INTFS_PREVIOUS=$previous_stored_intfs
            NODE_INTFS_STATUS_CODE=0  # Changed
        else
            if [ "$DEBUG" = "true" ]; then
              echo "Node interfaces count unchanged: $current_intfs"
            fi
            NODE_INTFS_CHANGED=false
            NODE_INTFS_STATUS_CODE=1 # unchanged
        fi
    else
        # No previous configuration found
        if [ "$DEBUG" = "true" ]; then
          echo "No previous node interfaces count found, setting initial value: $current_intfs"
        fi
        NODE_INTFS_CHANGED=true
        NODE_INTFS_STATUS_CODE=0
    fi
    
    # Always update file with current value
    echo "$current_intfs" > "$node_intfs_config" || {
        if [ "$DEBUG" = "true" ]; then
          echo "Failed to write to $node_intfs_config"
        fi
        NODE_INTFS_STATUS_CODE=2
        return 2
    }
    export NODE_INTFS_PREVIOUS
    export NODE_INTFS_CHANGED
    export NODE_INTFS_STATUS_CODE
    return $NODE_INTFS_STATUS_CODE
}