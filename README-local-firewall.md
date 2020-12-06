# IP Host Firewall

New connections destined for this host are firewalled except for basic ping and ssh, outbound is left open.

It is assumed Ubuntu will be used, initially developed on 20.04

# Installation

Running the command below will create a script that will:
* install `iptables-persistent` if missing
* flush iptables
* add the rules specified in this file
* then save rules to `/etc/iptables/rules.v{4,6}`

On boot the rules will be processed automatically.

```
rundoc run README-local-firewall.md
sudo ./firewall.sh
```

# Contents of install.sh

### Install Packages and Tools
```create-file:firewall.sh:744
#!/bin/bash
set -euo pipefail
apt-get -y install iptables-persistent
```

# firewall.sh

## Flush everything
```append-file:firewall.sh:744
iptables -F # Flush filter table
iptables -X # Delete all filter chains
iptables -Z # Flush all counters too

iptables -t nat -F
iptables -t nat -X

iptables -t mangle -F
iptables -t mangle -X

iptables -t raw -F
iptables -t raw -X
```

## Traffic destined to host

### Default Policies

Rule actions include DROP (block) or ALLOW

Default behaviors
* DROP all INPUT traffic - destined for this host
* DROP all FORWARD traffic - received by this host but destined for another, this only matters when the host is configured for forward IP traffic, acting as a router
* ALLOW all OUTPUT traffic - from local processes destined for remote hosts

```append-file:firewall.sh:744
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
```

### Always allowed traffic
Allow SSH
```append-file:firewall.sh:744
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

Allow ping (request is type 8, response is type 0)
```append-file:firewall.sh:744
iptables -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
iptables -A INPUT -p icmp -m icmp --icmp-type 0 -j ACCEPT
```

Accept any incoming connections that were already established
```append-file:firewall.sh:744
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

Allow any traffic to loopback device
```append-file:firewall.sh:744
iptables -A INPUT -i lo -j ACCEPT
```

### Always Blocked Traffic
Drop invalid packets
```append-file:firewall.sh:744
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
```

### Reject traffic with ICMP responses
Provide some reasonable ICMP messages for rejected tcp and udp packets, and indicate all other protocols are not valid
```append-file:firewall.sh:744
iptables -A INPUT -p udp -j REJECT --reject-with icmp-port-unreachable
iptables -A INPUT -p tcp -j REJECT --reject-with tcp-reset
iptables -A INPUT -j REJECT --reject-with icmp-proto-unreachable
```

## Rest of tables no-op
Do not NAT traffic, reset all the other tables

```append-file:firewall.sh:744
iptables -t nat -P PREROUTING ACCEPT
iptables -t nat -P INPUT ACCEPT
iptables -t nat -P OUTPUT ACCEPT
iptables -t nat -P POSTROUTING ACCEPT

iptables -t raw -P PREROUTING ACCEPT
iptables -t raw -P OUTPUT ACCEPT

iptables -t security -P INPUT ACCEPT
iptables -t security -P OUTPUT ACCEPT
iptables -t security -P FORWARD ACCEPT

iptables -t mangle -P PREROUTING ACCEPT
iptables -t mangle -P INPUT ACCEPT
iptables -t mangle -P FORWARD ACCEPT
iptables -t mangle -P OUTPUT ACCEPT
iptables -t mangle -P POSTROUTING ACCEPT
```

## Block IPv6

Just block all ipv6
```append-file:firewall.sh:744
ip6tables -A INPUT -j REJECT --reject-with adm-prohibited
ip6tables -A OUTPUT -j REJECT --reject-with adm-prohibited
ip6tables -A FORWARD -j REJECT --reject-with adm-prohibited
```
