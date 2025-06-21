#!/bin/bash
# collect_network_info.sh
# Collects comprehensive network information and saves it to a file

OUTPUT_FILE="network_info_$(hostname)_$(date +%Y%m%d_%H%M%S).txt"

{
  echo "==== Hostname and FQDN ===="
  hostname -f
  echo

  echo "==== Network Interfaces (ip addr) ===="
  ip addr
  echo

  echo "==== Routing Table (ip route) ===="
  ip route
  echo

  echo "==== DNS Resolver (/etc/resolv.conf) ===="
  cat /etc/resolv.conf
  echo

  echo "==== Firewall Rules (iptables -L -n -v) ===="
  iptables -L -n -v 2>/dev/null || echo "iptables not available"
  echo

  echo "==== NetworkManager Connections (nmcli) ===="
  nmcli connection show 2>/dev/null || echo "nmcli not available"
  echo

  echo "==== /etc/network/interfaces (if present) ===="
  [ -f /etc/network/interfaces ] && cat /etc/network/interfaces || echo "/etc/network/interfaces not present"
  echo

  echo "==== /etc/hosts ===="
  cat /etc/hosts
  echo

  echo "==== ARP Table (ip neigh) ===="
  ip neigh
  echo

  echo "==== Listening Ports (ss -tulpen) ===="
  ss -tulpen 2>/dev/null || netstat -tulpen 2>/dev/null || echo "ss/netstat not available"
  echo
} > "$OUTPUT_FILE"

echo "Network information collected in $OUTPUT_FILE"