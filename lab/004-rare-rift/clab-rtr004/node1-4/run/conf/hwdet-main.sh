#!/bin/sh


while (true); do
  cd /rtr/run/conf/
  stty raw < /dev/tty
  java -Xmx1024m -jar /rtr/rtr.jar router /rtr/run/conf/rtr-
  if [ $? -eq 4 ] ; then
    sync
    reboot -f
  fi
  stty cooked < /dev/tty
  sleep 1
  done
