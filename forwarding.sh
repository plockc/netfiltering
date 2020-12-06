#!/bin/bash
set -euo pipefail
CIDR="%:INTERNAL_NETWORK_ADDRESS:%"
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-ip-forwarding.conf
iptables -A FORWARD -p tcp ! --destination "$CIDR" -j ACCEPT
iptables -A FORWARD -p udp ! --destination "$CIDR" -j ACCEPT
iptables -A FORWARD -p icmp ! --destination "$CIDR" -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -p icmp -m icmp --icmp-type 8 -j ACCEPT
iptables -A FORWARD -p icmp -m icmp --icmp-type 0 -j ACCEPT
iptables -A FORWARD -j REJECT --reject-with icmp-host-unreachable
