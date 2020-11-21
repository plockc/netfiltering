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
sudo rundoc run -a README.md
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

### Install firewall and internet firewall
```create-file:install.sh
#!/bin/bash
set -euo pipefail
source firewall.sh
source fowarding.sh
```

### Verify iptables Rules
```append-file:install.sh
sudo iptables-restore -t rules.v4
sudo ip6tables-restore -t rules.v6
```

### Configure netfilter-persistent
Install the rules and restart netfilter
```append-file:install.sh
sudo mv rules.v{4,6} /etc/iptables/
sudo netfilter-persistent reload  # reloads all the rules
```
