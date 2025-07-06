#!/bin/bash

if ! source /rtr/functions.sh; then
    echo "Error: Could not load functions file"
    exit 1
fi

# debug flag
if [ "$DEBUG" = "true" ]; then
    set -x
fi

HW_PENULTIMATE_LINE=`wc -l ${CONF_DIR}/rtr-hw.txt | awk '{print $1}'`

SW_PENULTIMATE_LINE=`wc -l ${CONF_DIR}/rtr-sw.txt | awk '{print $1}'`

if [ "$FIRST_BOOT" = "true" ]; then
    configure_hw_file
    configure_mgmt_eth255
    initialize_rtr
elif [ $DATAPLANE_STATUS_CODE -eq 0 ] || [ $DATAPLANE_STATUS_CODE -eq 1 ]; then
    configure_hw_file
    configure_mgmt_eth255
    initialize_rtr
else
    if [ $NODE_INTFS_STATUS_CODE -eq 0 ] || [ $NODE_INTFS_STATUS_CODE -eq 1 ]; then
        configure_hw_file
        configure_mgmt_eth255
        initialize_rtr
    fi
fi

# flush docker eth0 config 
# so that freeRtr management connectivity 
# will take precedence over Linux container 
ip addr flush dev eth0

exit 0