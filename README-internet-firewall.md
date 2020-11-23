# IP Gateway Firewall

This provides handling of forwarded packets (packets go through this host, but does not originate from or target this host).

One of the connected networks is consider the internal network and egress of all traffic to external hosts is allowed but all ingress is blocked expect for ping and ssh unless the connection originated from internal hosts.

Given that home networks typically NAT at the internal gateway, ssh into the network will have to be port forwarded to the internal IP address.

The network and interface configuration is not covered here, only how to filter the traffic.

# Installation

It's expected that rules.v4 has already been created with the contents as described in README-local-firewall.md, which sets up basic filtering for traffic to and from this host.

Running this script below will append to the existing rules.v4 file based on the rules described in this file, that file can be moved to `/etc/iptables/` and will be read in if `iptables-persistent` package is installed, and leveraged if ip forwarding is enabled on the host.

### Enable Forwarding of Packets
```create-file:forwarding.sh:744
#!/bin/bash
set -euo pipefail
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-ip-forwarding.conf
```

### Build iptables Rules
```
rundoc run -a README-internet-firewall.md
```

## Define the Internal Network

```env
INTERNAL_NETWORK_ADDRESS=192.168.0.0/24
```

## Allowed Traffic

General idea is to only allow routing for connections initiated in the protected internal network.

Allow forwarding of any tcp, udp, and icmp traffic outbound.  
```r-append-file:rules.v4
* filter
-A FORWARD -p tcp ! --destination %:INTERNAL_NETWORK_ADDRESS:% -j ACCEPT
-A FORWARD -p udp ! --destination %:INTERNAL_NETWORK_ADDRESS:% -j ACCEPT
-A FORWARD -p icmp ! --destination %:INTERNAL_NETWORK_ADDRESS:% -j ACCEPT
```

Forward any packets on already established connections, this allows return traffic initiated by internal hosts.  The default policy to DROP will prevent NEW connections from external networks.
```append-file:rules.v4
-A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
```

Forward packets for explicitly allowed services, such as `ssh` port and ICMP for `ping`
```append-file:rules.v4
-A FORWARD -p tcp --dport 22 -j ACCEPT
-A FORWARD -p tcp --dport 80 -j ACCEPT
-A FORWARD -p tcp --dport 443 -j ACCEPT
-A FORWARD -p icmp -m icmp --icmp-type 8 -j ACCEPT
-A FORWARD -p icmp -m icmp --icmp-type 0 -j ACCEPT
```

ICMP message for rejected traffic
```append-file:rules.v4
-A FORWARD -j REJECT --reject-with icmp-host-unreachable
```

## Commit

```append-file:rules.v4
COMMIT
```
