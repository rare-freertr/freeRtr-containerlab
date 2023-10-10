#!/bin/bash

set -e

set -x

type -p containerlab || { echo "containerlab must be installed"; exit 1; }

#echo 0.a. 
git clone https://github.com/rare-freertr/freeRtr-containerlab && cd ./freeRtr-containerlab/lab/005-rare-hello-fod

#0.b. 
containerlab destroy -t rtr005.clab.yml || true
containerlab deploy -t rtr005.clab.yml

#0.c. 
containerlab inspect -t rtr005.clab.yml # for later inspection, if needed

sleep 10 # need enough time for freertr to be ready

#1.a.

docker exec -ti clab-rtr005-host1 ifconfig eth1 10.1.10.1 netmask 255.255.255.0
docker exec -ti clab-rtr005-host1 route add -net 10.2.10.0 netmask 255.255.255.0 gw 10.1.10.10 

docker exec -ti clab-rtr005-host2 ifconfig eth1 10.2.10.2 netmask 255.255.255.0
docker exec -ti clab-rtr005-host2 route add -net 10.1.10.0 netmask 255.255.255.0 gw 10.2.10.10 

docker exec -ti clab-rtr005-host1 ping -c 5 10.2.10.2
docker exec -ti clab-rtr005-host2 ping -c 5 10.1.10.1

#1.b. Check freetrtr (freertr is already configured as needed by ./clab-rtr005/rtr1/run/conf/rtr-sw.txt : interface as well as server bgp config)

#docker exec -ti clab-rtr005-rtr1 sh -c 'apt-get update && apt-get install netcat-traditional'
#docker exec -ti clab-rtr005-rtr1 sh -c '{ echo "show ipv4 bgp 1 flowspec database"; echo "show policy-map flowspec CORE ipv4"; echo exit; } | netcat 127.1 2323'
docker exec -ti clab-rtr005-rtr1 bash -c '{ echo "show ipv4 bgp 1 flowspec database"; echo "show policy-map flowspec CORE ipv4"; echo exit; } | (exec 3<>/dev/tcp/127.0.0.1/2323; cat >&3; cat <&3; exec 3<&-)'

# 2.
docker exec -ti clab-rtr005-fod1 ifconfig eth1 10.3.10.3/24
docker exec -ti clab-rtr005-fod1 ./exabgp/run-exabgp-generic --init-conf 10.3.10.3 10.3.10.3 1001 10.3.10.10 10.3.10.10 2001 -- --supervisord --restart
#to check the exabgp stdout: 
docker exec -ti clab-rtr005-fod1 tail log/exabgp-stdout.log

# 3.
docker exec -ti clab-rtr005-fod1 ./inst/helpers/enable_rule.sh 10.1.10.1/32 10.2.10.2/32 1 1 # first parameter: src IP prefix; second parameter: dst IP prefix; last but one parameter: 1=icmp ; last parameter: 1=enable rule on router, i.e., push it now
! docker exec -ti clab-rtr005-host1 ping -c 10 10.2.10.2
! docker exec -ti clab-rtr005-host2 ping -c 10 10.1.10.1
docker exec -ti clab-rtr005-rtr1 bash -c '{ echo "show ipv4 bgp 1 flowspec database"; echo "show policy-map flowspec CORE ipv4"; echo exit; } | (exec 3<>/dev/tcp/127.0.0.1/2323; cat >&3; cat <&3; exec 3<&-)'

# 4.
docker exec -ti clab-rtr005-fod1 ./inst/helpers/enable_rule.sh 10.1.10.1/32 10.2.10.2/32 1 0 # first parameter: src IP prefix; second parameter: dst IP prefix; last but one parameter: 1=icmp ; last parameter: 0=disable rule on router if it exists and is active or just create rule in INACTIVE state in FoD DB 
docker exec -ti clab-rtr005-host1 ping -c 10 10.2.10.2
docker exec -ti clab-rtr005-host2 ping -c 10 10.1.10.1
docker exec -ti clab-rtr005-rtr1 bash -c '{ echo "show ipv4 bgp 1 flowspec database"; echo "show policy-map flowspec CORE ipv4"; echo exit; } | (exec 3<>/dev/tcp/127.0.0.1/2323; cat >&3; cat <&3; exec 3<&-)'


