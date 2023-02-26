# freeRtr-containerlab
RARE/freeRtr for Containerlab Network Operating System networks simulator

This is an early version of RARE/freeRtr for containerlab network simulator.

## 1. **[TL;DR]** Quick start (5s)

We are cheating a bit here ! :-) 

`5s` assumes:

* that you already built the image or you are using an image from external container repository
* that `containerlab` is already installed

```
git clone https://github.com/rare-freertr/freeRtr-containerlab.git
cd freeRtr-containerlab
```

* Build container

If you want to build RARE/freeRtr container

```
docker build --no-cache -t freertr-containerlab:latest .
```
>We are working on providing a rolling release of RARE/freeRtr image using popular repository such as Dockerhub ...
>Please be patient and stay tuned !

## 2. Lab example 

* Lab diagram

```
rtr1 <--eth1--> rtr2
``` 

* Run `containerlab` with the generated image and **containerlab** lab example
```
containerlab deploy --topo rtr00.clab.yml 
```
## Lab configuration

As a `Hello-world` example, we will configure the interconnectivity between `rtr1` and `rtr2`

Containerlab should display the output below:
```
~/# containerlab deploy --topo rtr00.clab.yml
INFO[0000] Containerlab v0.37.0 started
INFO[0000] Parsing & checking topology file: rtr00.clab.yml
INFO[0000] Creating lab directory: /root/clab-test/clab-rtr00
INFO[0000] Creating docker network: Name="clab", IPv4Subnet="172.20.20.0/24", IPv6Subnet="2001:172:20:20::/64", MTU="1500"
INFO[0000] Creating container: "rtr2"
INFO[0000] Creating container: "rtr1"
INFO[0001] Creating virtual wire: rtr1:eth1 <--> rtr2:eth1
INFO[0002] Adding containerlab host entries to /etc/hosts file
+---+-----------------+--------------+--------------+-------+---------+----------------+----------------------+
| # |      Name       | Container ID |    Image     | Kind  |  State  |  IPv4 Address  |     IPv6 Address     |
+---+-----------------+--------------+--------------+-------+---------+----------------+----------------------+
| 1 | clab-rtr00-rtr1 | 244d9da2dcb6 | freertr:clab | linux | running | 172.20.20.3/24 | 2001:172:20:20::3/64 |
| 2 | clab-rtr00-rtr2 | c178a80f65b3 | freertr:clab | linux | running | 172.20.20.2/24 | 2001:172:20:20::2/64 |
+---+-----------------+--------------+--------------+-------+---------+----------------+----------------------+
```

- Access `rtr1`
  - Default login/password is `rare`/`rare`
  - Using Docker
```
~# docker exec -it clab-rtr00-rtr1 /bin/bash
root@rtr1:~# telnet localhost 2323

Trying ::1...
Connection failed: Connection refused
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
welcome
username:rare
password:
line ready
rtr1#
```
  - Using ContainerLab OOB management

**OOBM IPv4 address**
```
~# telnet 172.20.20.3
Trying 172.20.20.3...
Connected to 172.20.20.3.
Escape character is '^]'.
welcome
username:rare
password:
line ready
rtr1#
```

**OOBM IPv6 address**
```
~# telnet 2001:172:20:20::3
Trying 2001:172:20:20::3...
Connected to 2001:172:20:20::3.
Escape character is '^]'.
welcome
username:rare
password:
line ready
rtr1#
```
* Configure hostname to `rtr1`, VRF `CORE` and `rtr1@eth1` with LLDP assign IPv4 and IPv6

```
rtr1#conf t
rtr1(cfg)#vrf definition CORE
rtr1(cfg-vrf)#exit
rtr1(cfg)#interface ethernet1
rtr1(cfg-if)#vrf forwarding CORE
rtr1(cfg-if)#ipv4 address 10.1.2.0 /31
rtr1(cfg-if)#ipv6 address fd00::1:2:0 /127
rtr1(cfg-if)#lldp enable
rtr1(cfg-if)#end
rtr1#wr
% saving configuration
% success
rtr1#
```

For the sake of simplicity, we will repeat the steps above for `rtr2` (sorry for nerdy power-user :laughing:)

- Access `rtr2`
  - Default login/password is `rare`/`rare`
  - Using Docker
```
~# docker exec -it clab-rtr00-rtr2 /bin/bash
root@rtr2:~# telnet localhost 2323
Trying ::1...
Connection failed: Connection refused
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
welcome
username:rare
password:
line ready
rtr2#
```
- Using ContainerLab OOB management

**OOBM IPv4 address**
```
~# telnet 172.20.20.2
Trying 172.20.20.2...
Connected to 172.20.20.2.
Escape character is '^]'.
welcome
username:rare
password:
line ready
rtr2#
```

**OOBM IPv6 address**
```
~# telnet 2001:172:20:20::2
Trying 2001:172:20:20::2...
Connected to 2001:172:20:20::2.
Escape character is '^]'.
welcome
username:rare
password:
line ready
rtr2#
```
* Configure hostname to `rtr2`, VRF `CORE` and `rtr2@eth1` with LLDP assign IPv4 and IPv6

```
rtr2#conf t
rtr2(cfg)#vrf definition CORE
rtr2(cfg-vrf)#exit
rtr2(cfg)#interface ethernet1
rtr2(cfg-if)#vrf forwarding CORE
rtr2(cfg-if)#ipv4 address 10.1.2.1 /31
rtr2(cfg-if)#ipv6 address fd00::1:2:1 /127
rtr2(cfg-if)#lldp enable
rtr2(cfg-if)#end
rtr2#wr
% saving configuration
% success
rtr2#
```

## 3. Verification

* From `rtr1`

```
rtr1#show lldp neighbor
interface  hostname  iface      ipv4      ipv6
ethernet1  rtr2      ethernet1  10.1.2.1  fd00::1:2:1

rtr1#ping 10.1.2.1 vrf CORE source ethernet1
pinging 10.1.2.1, src=10.1.2.0, vrf=CORE, cnt=5, len=64, df=false, tim=1000, gap=0, ttl=255, tos=0, sgt=0, flow=0, fill=0, alrt=-1, sweep=false, multi=false
!!!!!
result=100.0%, recv/sent/lost/err=5/5/0/0, took 22, min/avg/max/dev rtt=1/1.4/2/0.2, ttl 255/255/255/0.0, tos 0/0.0/0/0.0
rtr1#ping fd00::1:2:1 vrf CORE source ethernet1
pinging fd00::1:2:1, src=fd00::1:2:0, vrf=CORE, cnt=5, len=64, df=false, tim=1000, gap=0, ttl=255, tos=0, sgt=0, flow=0, fill=0, alrt=-1, sweep=false, multi=false
!!!!!
result=100.0%, recv/sent/lost/err=5/5/0/0, took 5, min/avg/max/dev rtt=1/1.0/1/0.0, ttl 255/255/255/0.0, tos 0/0.0/0/0.0
rtr1#
```

* From `rtr2`

```
rtr2#show lldp neighbor
interface  hostname  iface      ipv4      ipv6
ethernet1  rtr1      ethernet1  10.1.2.0  fd00::1:2:0

rtr2#ping 10.1.2.0 vrf CORE source ethernet1
pinging 10.1.2.0, src=10.1.2.1, vrf=CORE, cnt=5, len=64, df=false, tim=1000, gap=0, ttl=255, tos=0, sgt=0, flow=0, fill=0, alrt=-1, sweep=false, multi=false
!!!!!
result=100.0%, recv/sent/lost/err=5/5/0/0, took 21, min/avg/max/dev rtt=1/1.4/2/0.2, ttl 255/255/255/0.0, tos 0/0.0/0/0.0
rtr2#ping fd00::1:2:0 vrf CORE source ethernet1
pinging fd00::1:2:0, src=fd00::1:2:1, vrf=CORE, cnt=5, len=64, df=false, tim=1000, gap=0, ttl=255, tos=0, sgt=0, flow=0, fill=0, alrt=-1, sweep=false, multi=false
!!!!!
result=100.0%, recv/sent/lost/err=5/5/0/0, took 6, min/avg/max/dev rtt=1/1.0/1/0.0, ttl 255/255/255/0.0, tos 0/0.0/0/0.0
rtr2#
```

Congratulation ! You have just run your first `RARE/freeRtr` within `containerlab` !
> In this example, we have showed a simple lab with 2 `RARE/freeRtr`, but nothing prevents you to create any architecture mixing any other nodes from different vendor flavor. We have our own CI/CD for interoperability tests and we are `100%` compatible with any other NOS. (Cisco IOS-XE, Cisco IOS-XR, Cisco NX-OS, Junos, Arista OS, Nokia SR-OS, FRR, SONIC, <you name it ...> )

If you find an interoperability issue with `RARE/freeRtr`, please do contact us so we can adjust our software !
  
## 4. This is just the beginning -> Next step
  
`freeRtr-containerlab` is a continuous work-in-progress and EXCITING project. 
  
We are pretty conscious of missing points:

  * ~~CI/CD of `RARE/freeRtr` freeRtr-container lab creation~~ :arrow_right: `DONE !`
  
  `i.e` `freertr-containerlab:latest` is re-generated very day with latest greated [RARE/freeRtr](https://github.com/rare-freertr/freeRtr) control plane software
  
  * ~~Integration of management port to `RARE/freeRtr` containerlab~~ :arrow_right: `DONE !`
  
  `i.e` `freeRtr-containerlab:latest` can be accessed either using `docker exec` or containerlab `oob` management address with `telnet`. (see above)
  
  
Feel free to join us if you feel ready to dive into the code and gets your hand dirty. 
  
Enjoy your `RARE/freeRtr` experience with `containerlab` !
  
  
## 5. Acknowledgement
  
Special thanks to:
  * [containerlab](https://containerlab.dev/)  
 
  Particularly [Roman DODIN](https://github.com/hellt) for his warm welcome and super blazingly fast answer in `containerlab Discord` server 

  * [freeRtr](www.freertr.org) 
  
  Particularly [Csaba MATE](http://mc36.nop.hu/) for his `almost` :innocent: bug free code !
  
  
