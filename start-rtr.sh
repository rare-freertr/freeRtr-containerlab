#!/bin/bash

sleep 3 

TRG=/rtr

# Network interface detection during container boots
$TRG/hwdet-init.sh

# Start RARE/freeRtr using hwdet-init.sh artefact result 
$TRG/hwdet-all.sh

# Prevent container from exiting
while true; do sleep 1; done
