#!/bin/bash
set -euo pipefail
./firewall.sh
./forwarding.sh
sudo iptables-restore -t rules.v4
sudo ip6tables-restore -t rules.v6
sudo mv rules.v{4,6} /etc/iptables/
sudo netfilter-persistent reload  # reloads all the rules
