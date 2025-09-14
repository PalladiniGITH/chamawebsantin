#!/bin/bash
set -e
apt-get update
apt-get install -y nmap curl hydra sqlmap git
if [ ! -d /opt/testssl.sh ]; then
  git clone --depth 1 https://github.com/drwetter/testssl.sh.git /opt/testssl.sh
fi
