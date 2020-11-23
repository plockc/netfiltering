# IP Host Firewall

New connections destined for this host are firewalled except for basic ping and ssh, outbound is left open.

It is assumed Ubuntu will be used, initially developed on 20.04

# Installation

Running this script below will create a rules.v4 file based on the rules described in this file, that file can be moved to `/etc/iptables/` and on boot will be read in if `iptables-persistent` package is enabled.
```
rundoc run README-iptables.md
```

# install.sh

### Install Packages and Tools
```create-file:firewall.sh:744
#!/bin/bash
set -euo pipefail
sudo apt-get -y install iptables-persistent
```

# rules.v4

```bash
if [ -f rules.v4 ]; then rm rules.v4; fi
if [ -f rules.v6 ]; then rm rules.v6; fi
```

## Traffic destined to host

### Default Policies

Rule actions include DROP (block) or ALLOW

Default behaviors
* DROP all INPUT traffic - destined for this host
* DROP all FORWARD traffic - received by this host but destined for another, this only matters when the host is configured for forward IP traffic, acting as a router
* ALLOW all OUTPUT traffic - from local processes destined for remote hosts

```append-file:rules.v4
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
```

### Always allowed traffic
Allow SSH
```append-file:rules.v4
-A INPUT -p tcp --dport 22 -j ACCEPT
-A INPUT -p tcp --dport 80 -j ACCEPT
-A INPUT -p tcp --dport 443 -j ACCEPT
```

Allow ping (request is type 8, response is type 0)
```append-file:rules.v4
-A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
-A INPUT -p icmp -m icmp --icmp-type 0 -j ACCEPT
```

Accept any incoming connections that were already established
```append-file:rules.v4
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

Allow any traffic to loopback device
```append-file:rules.v4
-A INPUT -i lo -j ACCEPT
```

### Always Blocked Traffic
Drop invalid packets
```append-file:rules.v4
-A INPUT -m conntrack --ctstate INVALID -j DROP
```

### Reject traffic with ICMP responses
Provide some reasonable ICMP messages for rejected tcp and udp packets, and indicate all other protocols are not valid
```append-file:rules.v4
-A INPUT -p udp -j REJECT --reject-with icmp-port-unreachable
-A INPUT -p tcp -j REJECT --reject-with tcp-reset
-A INPUT -j REJECT --reject-with icmp-proto-unreachable
```

### Commit

```append-file:rules.v4
COMMIT
```

## Rest of tables no-op
Do not NAT traffic, reset all the other tables

```append-file:rules.v4
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT

*raw
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT

*security
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT

*mangle
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT
```

## Block IPv6

Just block all ipv6
```create-file:rules.v6
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT DROP [0:0]
COMMIT

*raw
:PREROUTING DROP [0:0]
:OUTPUT DROP [0:0]
COMMIT

*nat
:PREROUTING DROP [0:0]
:INPUT DROP [0:0]
:OUTPUT DROP [0:0]
:POSTROUTING DROP [0:0]
COMMIT

*security
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT DROP [0:0]
COMMIT

*mangle
:PREROUTING DROP [0:0]
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT DROP [0:0]
:POSTROUTING DROP [0:0]
COMMIT
```
