#!/bin/bash

# clock sync (mostly WSL issue)
#hwclock --hctosys

# Let container finish its network configuration
# There is no systemd "After" feature with Docker
sleep 3 

TRG=/rtr

# Network interface detection during container boots
$TRG/hwdet-init.sh

# Wait network discovery to complete 
sleep 1 

# Initialise management port
# on freeRtr rtr-hwtxt and rtr-sw.txt file 
$TRG/hwdet-mgmt.sh

# We are now readu to Start RARE/freeRtr
# using hwdet-init.sh artefacts result 
$TRG/hwdet-all.sh

# Prevent container from exiting
while true; do sleep 1; done
