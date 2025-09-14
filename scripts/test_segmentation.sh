#!/bin/bash
set -e
nmap -Pn 10.30.0.0/24 || true
for port in 3306 5432 22; do
  nc -zv 10.30.0.20 $port && echo "port $port open" || echo "port $port blocked"
done
