#!/bin/bash
set -euo pipefail
apt-get -y install iptables-persistent
./firewall.sh
./forwarding.sh
./persist.sh
