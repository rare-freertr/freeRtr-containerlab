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
wget www.freertr.org/fwd-`uname -m`.tgz
wget www.freertr.org/ifc-`uname -m`.tgz
wget www.freertr.org/ser-`uname -m`.tgz
wget www.freertr.org/utl-`uname -m`.tgz
wget www.freertr.org/snd-`uname -m`.tgz
cd $TMP/binTmp/
tar xfz ../binImg/fwd-`uname -m`.tgz
tar xfz ../binImg/ifc-`uname -m`.tgz
tar xfz ../binImg/ser-`uname -m`.tgz
tar xfz ../binImg/utl-`uname -m`.tgz
tar xfz ../binImg/snd-`uname -m`.tgz

mkdir -p $TRG

cat > $TRG/update.sh << EOF
#!/bin/sh
sudo apt update
sudo apt dist-upgrade
sudo apt remove apparmor
sudo apt autoremove
sudo apt clean
sudo sync
sudo fstrim -v -a -m 1M
#sudo e4defrag /
EOF
chmod +x $TRG/update.sh

echo Configuring freeRtr to $TRG directory

echo net.ipv6.conf.all.disable_ipv6=1 > /etc/sysctl.d/disableipv6.conf
echo net.ipv6.conf.default.disable_ipv6=1 >> /etc/sysctl.d/disableipv6.conf
echo kernel.panic=10 > /etc/sysctl.d/panic.conf

cp $TMP/src/rtr.jar $TRG/
cp $TMP/src/rtr.ver $TRG/
cp $TMP/binTmp/*.bin $TRG/
cp $TMP/binTmp/*.so $TRG/

sync

echo freeRtr installation file in $TRG finished! 

