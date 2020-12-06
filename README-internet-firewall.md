# IP Gateway Firewall

This provides handling of forwarded packets (packets go through this host, but does not originate from or target this host).

One of the connected networks is consider the internal network and egress of all traffic to external hosts is allowed but all ingress is blocked expect for ping and ssh unless the connection originated from internal hosts.

Given that home networks typically NAT at the internal gateway, ssh into the network will have to be port forwarded to the internal IP address.

The network and interface configuration is not covered here, only how to filter the traffic.

# Installation

It's expected that iptables has already been created with the contents as described in README-local-firewall.md, which sets up basic filtering for traffic to and from this host, and DROPs all forwarded traffic.

Running this script below will update the iptables rules as described in this file to enable forwarding, but not persist the rules.

```
rundoc run -a README-internet-firewall.md
sudo ./forwarding.sh
```

## Define the Internal Network

```env
INTERNAL_NETWORK_ADDRESS=192.168.0.0/24
```

## Contents of forwarding.sh

### Header

```r-create-file:forwarding.sh:744
#!/bin/bash
set -euo pipefail
CIDR="%:INTERNAL_NETWORK_ADDRESS:%"
```

### Enable Forwarding of Packets
```append-file:forwarding.sh:744
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-ip-forwarding.conf
```

### Allowed Traffic

General idea is to only allow routing for connections initiated in the protected internal network.

Allow forwarding of any tcp, udp, and icmp traffic outbound.  
```append-file:forwarding.sh:744
iptables -A FORWARD -p tcp ! --destination "$CIDR" -j ACCEPT
iptables -A FORWARD -p udp ! --destination "$CIDR" -j ACCEPT
iptables -A FORWARD -p icmp ! --destination "$CIDR" -j ACCEPT
```

Forward any packets on already established connections, this allows return traffic initiated by internal hosts.  The default policy to DROP will prevent NEW connections from external networks.
```append-file:forwarding.sh:744
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
```

Forward packets for explicitly allowed services, such as `ssh` port and ICMP for `ping`
```append-file:forwarding.sh:744
iptables -A FORWARD -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -p icmp -m icmp --icmp-type 8 -j ACCEPT
iptables -A FORWARD -p icmp -m icmp --icmp-type 0 -j ACCEPT
```

ICMP message for rejected traffic
```append-file:forwarding.sh:744
iptables -A FORWARD -j REJECT --reject-with icmp-host-unreachable
```

## NAT

### With route to internal network

The private network is not implicitly exposed except to the gateway.
On the upstream (internet) gateway, add a route for the test network
to the public IP of the firewall.

### Without ingress

If the northbound gateway can't have a route to the private network this host is firewalling, NAT all outbound traffic, which will also prevent ingress.

This will not be included in forwarding.sh, and replace the out interface appropriate for the host.

```
iptables -A POSTROUTING -out eth0 -j MASQUERADE
COMMIT
```

## Testing

### Test ingress

Verify connectivity with ping, which should be allowed to be forwarded.  Troubleshoot with tcpdump like:

```
sudo tcpdump ip net 192.168.0.0/24
```

On the private network host start a listener on a port that is allowed to be forwarded:
```
sudo nc -Nl -p 80
```

On a host outside the network (assuming there is a valid route)
```
echo Hello world | nc -N 192.168.0.200 80
```

Try with different port to verify it is blocked
