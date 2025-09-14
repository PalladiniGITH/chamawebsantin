#!/bin/bash
set -e
nft -f /etc/nftables.conf
sysctl -w net.ipv4.ip_forward=1
# keep container running
sleep infinity
