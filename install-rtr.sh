#!/bin/bash

TRG=/rtr
TMP=/root/install.rtr

mkdir -p $TMP
cd $TMP/
rm rtr.zip
wget www.freertr.org/rtr.zip
rm -rf rtr
unzip -o rtr.zip > /dev/null
rm $TMP/misc/default.cfg
wget -O $TMP/misc/default.cfg www.freertr.org/install-sw.txt
cd $TMP/src/
./d.sh
rm rtr.ver
wget www.freertr.org/rtr.ver
rm rtr.jar
wget www.freertr.org/rtr.jar
cd $TMP/binImg/
rm rtr-`uname -m`.tar
wget www.freertr.org/rtr-`uname -m`.tar
cd $TMP/binTmp/
tar xf ../binImg/rtr-`uname -m`.tar

mkdir -p $TRG

#cd $TMP/misc/service/
#./c.sh $TRG

cat > $TRG/update.sh << EOF
#!/bin/sh
sudo apt-get update
sudo apt-get dist-upgrade
sudo apt-get remove apparmor
sudo apt-get autoremove
sudo apt-get clean
sudo sync
sudo fstrim -v -a -m 1M
#sudo e4defrag /
EOF
chmod +x $TRG/update.sh

sync

echo freeRtr installation file in $TRG finished! 

