# netfiltering
Tools and documentation for managing network traffic for hosts, routers, and firewalls

# Executing the Installation

The actions of the installation follow this section, leveraging rundoc.

To install rundoc:
```
pip3 install --user rundoc
```

to create the install script:
```
rundoc run -a README.md
sudo ./install.sh
```

# Installation Script

## Define the Internal Network
```env
INTERNAL_NETWORK_ADDRESS=192.168.0.0/24
```

### Build iptables rules
```bash
rundoc run README-local-firewall.md
rundoc run README-internet-firewall.md
```

### Install firewall firewall and persist
```create-file:install.sh:744
#!/bin/bash
set -euo pipefail
apt-get -y install iptables-persistent
./firewall.sh
./forwarding.sh
./persist.sh
```

### Configure netfilter-persistent
Install the rules and restart netfilter
```create-file:persist.sh:744
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6
sudo netfilter-persistent reload  # reloads all the rules
```
