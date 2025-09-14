# ChamaWeb Security Lab

Este repositório simula uma pequena infraestrutura com três zonas de rede para estudos de segurança ofensiva e defensiva. Todos os serviços são executados localmente via Docker Compose.

## Topologia

```
[kali] --(internet)-- [fw] --(dmz)-- [nginx-waf] --(internal)-- [api-gateway, mysql, keycloak]
```

- **internet (10.10.0.0/24)**: contém o atacante `kali`.
- **dmz (10.20.0.0/24)**: expõe apenas o proxy `nginx-waf` em HTTPS.
- **internal (10.30.0.0/24)**: abriga `api-gateway`, `mysql` e `keycloak`.
- `fw` roteia e filtra o tráfego entre as redes usando `nftables`.

> **Nota:** pfSense não roda em Docker. O contêiner `fw` é apenas um substituto simples para laboratório. Para utilizar o pfSense real, instale-o em uma VM com três NICs (WAN/DMZ/LAN) mantendo as mesmas sub-redes e rotas descritas acima.

## Pré-requisitos
- Docker e Docker Compose plugin
- Portas livres na máquina host (443)

## Uso

1. Gere certificados autoassinados:
   ```bash
   make certs
   ```
2. Suba o laboratório:
   ```bash
   make up
   ```
3. Aplique os testes de segurança:
   ```bash
   make test-recon
   make test-bruteforce
   make test-sqli
   make test-tls
   make test-segmentation
   ```
4. Para encerrar:
   ```bash
   make down
   ```

## Credenciais de exemplo
- **Banco de Dados:** usuário em `secrets/db_user.example` com senha em `secrets/db_password.example` (somente DML).
- **Keycloak:** usuário administrador definido em `secrets/kc_admin_user.example` e `secrets/kc_admin_password.example`; realm `ChamaWeb` com client `portal` e usuário `testuser` que exige MFA (TOTP).

Altere os arquivos em `secrets/` para valores reais antes de executar o laboratório.

## Wazuh (opcional)
Existe um serviço placeholder chamado `wazuh` com profile `wazuh`. Para habilitar uma stack oficial, substitua-o pela configuração real e execute:
```bash
docker compose --profile wazuh up
```

## Testes disponíveis
Os scripts em `scripts/` executam verificações automatizadas a partir do contêiner `kali` (exceto `test_segmentation.sh`, executado da DMZ). Eles validam recon, brute force, SQLi/XSS, configuração TLS e segmentação de redes.

## Estrutura de diretórios
- `fw/` – Dockerfile, entrypoint e regras `nftables`.
- `nginx/` – proxy reverso com ModSecurity/OWASP CRS.
- `api/` – API stub em FastAPI com consultas preparadas ao MySQL.
- `initdb/` – scripts de inicialização do banco com usuário de privilégio reduzido.
- `scripts/` – utilitários e testes automatizados.
- `secrets/` – arquivos de exemplo para Docker secrets.

## Licença
Projeto de laboratório educativo.
