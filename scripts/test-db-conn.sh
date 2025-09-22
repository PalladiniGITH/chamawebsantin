#!/usr/bin/env bash
set -euo pipefail

HOST=${DATABASE_HOST:-192.168.8.34}
PORT=${DATABASE_PORT:-3306}

echo "Testando conexão TCP para ${HOST}:${PORT}"
if nc -zv "$HOST" "$PORT"; then
  echo "Porta aberta"
else
  echo "Não foi possível conectar na porta ${PORT} do host ${HOST}" >&2
  exit 1
fi
