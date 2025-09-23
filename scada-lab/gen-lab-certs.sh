#!/usr/bin/env bash
set -euo pipefail

WORKDIR="${PWD}/lab-pki"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

PF_IP="192.168.8.33"
DMZ_IP="192.168.8.50"
LAN_IP="192.168.8.34"
CN="${DMZ_IP}"
DAYS=825

echo "Gerando PKI em: $WORKDIR"

openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 -out ca.crt \
  -subj "/C=BR/ST=PR/L=Curitiba/O=LabGrupo8/OU=CA/CN=Lab-CA-Grupo8"

cat > server.cnf <<EOF_INNER
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = BR
ST = PR
L = Curitiba
O = LabGrupo8
OU = Web
CN = ${CN}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
IP.1 = ${DMZ_IP}
IP.2 = ${PF_IP}
IP.3 = ${LAN_IP}
DNS.1 = localhost
DNS.2 = web.grupo8.local
EOF_INNER

openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -config server.cnf

cat > v3ext.cnf <<EOF_INNER
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
IP.1 = ${DMZ_IP}
IP.2 = ${PF_IP}
IP.3 = ${LAN_IP}
DNS.1 = localhost
DNS.2 = web.grupo8.local
EOF_INNER

openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out server.crt -days ${DAYS} -sha256 -extfile v3ext.cnf

cat server.crt ca.crt > server_fullchain.pem
openssl pkcs12 -export -out server.p12 -inkey server.key -in server.crt -certfile ca.crt -passout pass:labp12pass

chmod 640 server.key ca.key
echo "Gerado: ca.crt, server.crt, server_fullchain.pem, server.key, server.p12 (senha labp12pass)"
echo "Copie server_fullchain.pem -> ../scada-lab/certs/server.crt e server.key -> ../scada-lab/certs/server.key"
