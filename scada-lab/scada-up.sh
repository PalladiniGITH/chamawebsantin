#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
echo "Construindo e subindo containers..."
docker-compose up -d --build
echo "Aguardando 10s para Tomcat iniciar..."
sleep 10
echo "Verificando containers:"
docker-compose ps
echo
echo "Exibir logs principais (scadabr):"
docker logs --tail 200 scadabr || true
echo
echo "Exibir logs do simulador modbus:"
docker logs --tail 200 modbus-sim || true
