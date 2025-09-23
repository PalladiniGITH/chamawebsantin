#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

SCADABR_WAR_PATH="scadabr/scadabr.war"
if [[ ! -f "$SCADABR_WAR_PATH" ]]; then
  cat <<EOF
[ERRO] Arquivo "$SCADABR_WAR_PATH" não encontrado.
Baixe o WAR oficial do ScadaBR e salve-o nesse caminho antes de executar este script.
Exemplo de download (ajuste a URL para a versão desejada):
  curl -L -o "$SCADABR_WAR_PATH" "https://exemplo.com/path/para/scadabr.war"
EOF
  exit 1
fi

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
