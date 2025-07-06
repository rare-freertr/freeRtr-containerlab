#!/bin/bash

# clock sync (mostly WSL issue)
# hwclock --hctosys

chmod u+x $TRG /rtr/functions.sh

if ! source /rtr/functions.sh; then
    echo "Error: Could not load functions file"
    exit 1
fi

chmod u+x $TRG/*.sh

first_boot
check_dataplane_type

# 1- Network interface detection during container boots
# 2- Wait network discovery to complete
# 3- Initialise management port
#    on freeRtr rtr-hwtxt and rtr-sw.txt file 
# 4- Initialise dataplane
$TRG/hwdet-init.sh && $TRG/hwdet-mgmt.sh && $TRG/hwdet-dataplane.sh

# We are now ready to Start RARE/freeRtr
while (true); do
  cd /rtr/run/conf/
  stty raw < /dev/tty
  java -jar $TRG/rtr.jar routerc $CONF_DIR/rtr-
  remove_p4_telnet
  if [ $? -eq 4 ] ; then
    sync
    reboot -f
  fi
  stty cooked < /dev/tty
  sleep 1
done

# Prevent container from exiting
while true; do sleep 1; done
