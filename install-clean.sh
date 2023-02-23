#!/bin/sh

# Cleaning freeRtr install artefact

BASE=/root
TMP=$BASE/install.rtr

apt autoremove && sudo apt clean

#rm -rf $TMP
#rm $BASE/install-deps.sh
#rm $BASE/install-rtr.sh
#rm $BASE/install-clab.sh

sync
