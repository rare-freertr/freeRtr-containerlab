#!/bin/bash

if ! source /rtr/functions.sh; then
    echo "Error: Could not load functions file"
    exit 1
fi

# debug flag
if [ "$DEBUG" = "true" ]; then
    set -x
fi

if [ "$FIRST_BOOT" = "true" ]; then
    # default vrf initialization
    if [ "$INIT_VRF" = "true" ]; then
        create_vrf_core
        add_vrf_forwarding_to_interfaces
    fi
    initialize_rtr
    cp $HW_FILE $HW_FILE.bak
    cp $SW_FILE $SW_FILE.bak
    if [ "$DATAPLANE_TYPE" != "pcapInt" ]; then
        echo "dataplane type is $DATAPLANE_TYPE"
        java -jar $TRG/rtr.jar test hwext path $CONF_DIR/rtr- dataplane $DATAPLANE_TYPE
        remove_p4_telnet
    fi
    initialize_rtr

elif [ $DATAPLANE_STATUS_CODE -eq 0 ]; then
    # default vrf initialization
    if [ "$INIT_VRF" = "true" ]; then
        create_vrf_core
        add_vrf_forwarding_to_interfaces
    fi
    initialize_rtr

elif [ $DATAPLANE_STATUS_CODE -eq 0 ]; then
    if [ "$DATAPLANE_TYPE" != "pcapInt" ]; then
        # default vrf initialization
        if [ "$INIT_VRF" = "true" ]; then
            create_vrf_core
            add_vrf_forwarding_to_interfaces
        fi
        initialize_rtr
        cp $HW_FILE $HW_FILE.bak
        cp $SW_FILE $SW_FILE.bak
        echo "dataplane type is $DATAPLANE_TYPE"
        java -jar $TRG/rtr.jar test hwext path $CONF_DIR/rtr- dataplane $DATAPLANE_TYPE
        remove_p4_telnet
        initialize_rtr
    fi
elif [ $DATAPLANE_STATUS_CODE -eq 1 ]; then
    if [ "$DATAPLANE_TYPE" != "pcapInt" ]; then
        # default vrf initialization
        if [ "$INIT_VRF" = "true" ]; then
            create_vrf_core
            add_vrf_forwarding_to_interfaces
        fi
        initialize_rtr
        cp $HW_FILE $HW_FILE.bak
        cp $SW_FILE $SW_FILE.bak
        echo "dataplane type is $DATAPLANE_TYPE"
        java -jar $TRG/rtr.jar test hwext path $CONF_DIR/rtr- dataplane $DATAPLANE_TYPE
        remove_p4_telnet
        initialize_rtr
    fi
elif [ $NODE_INTFS_STATUS_CODE -eq 0 ] || [ $NODE_INTFS_STATUS_CODE -eq 1 ]; then
    if [ "$DATAPLANE_TYPE" != "pcapInt" ]; then
        # default vrf initialization
        if [ "$INIT_VRF" = "true" ]; then
            create_vrf_core
            add_vrf_forwarding_to_interfaces
        fi
        initialize_rtr
        cp $HW_FILE $HW_FILE.bak
        cp $SW_FILE $SW_FILE.bak
        echo "dataplane type is $DATAPLANE_TYPE"
        java -jar $TRG/rtr.jar test hwext path $CONF_DIR/rtr- dataplane $DATAPLANE_TYPE
        remove_p4_telnet
        initialize_rtr
    fi
fi

echo "do write" >> $CONF_DIR/rtr-sw.txt

exit 0