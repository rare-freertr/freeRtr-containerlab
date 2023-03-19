#!/bin/bash

# clock sync (mostly WSL issue)
# hwclock --hctosys

# Let container finish its network configuration
# There is no systemd "After" feature with Docker
sleep 3 

TRG=/rtr
RUN_DIR=$TRG/run
CONF_DIR=$RUN_DIR/conf

# Network interface detection during container boots
$TRG/hwdet-init.sh

# Wait network discovery to complete 
sleep 1 

# Initialise management port
# on freeRtr rtr-hwtxt and rtr-sw.txt file 
$TRG/hwdet-mgmt.sh

# We are now ready to Start RARE/freeRtr
# using hwdet-init.sh artefact results
if [ -f "$CONF_DIR/hwdet-all.sh" ] ; then
  echo "Starting RARE/freeRtr ..."
  $CONF_DIR/hwdet-all.sh
else
  echo "Error starting RARE/freeRtr: ${CONF_DIR} does not exist !"
fi

sleep 1

# Prevent container from exiting
while true; do sleep 1; done
