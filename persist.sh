iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6
sudo netfilter-persistent reload  # reloads all the rules
