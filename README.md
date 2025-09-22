# chamawebrest

Este projeto demonstra uma arquitetura simples de microserviços em PHP. Os serviços comunicam-se através de APIs REST e um API Gateway centraliza o acesso externo.

## Serviços

- **gateway**: expõe as rotas públicas e encaminha as requisições para os microserviços internos.
- **tickets**: responsável pelo gerenciamento de chamados.
- **stats**: fornece estatísticas agregadas usadas na página de relatórios.
- **db_check**: rotina auxiliar que aguarda a disponibilidade do MySQL externo antes de liberar os demais serviços.
- **shared/connect.php**: script único de conexão ao banco utilizado pelos serviços (lê as variáveis de ambiente).
- **front-end**: arquivos PHP e recursos estáticos servidos na raiz do projeto.
- **MySQL externo (192.168.8.34)**: banco compartilhado por todos os serviços, executado fora da DMZ.

## Pré-requisitos

1. Um servidor MySQL acessível a partir da rede da DMZ, ouvindo em `192.168.8.34:3306` (ajuste os valores se necessário).
2. Um banco de dados criado para a aplicação (ex.: `chamaweb`) e um usuário com privilégios adequados (ex.: `app_user`).
3. Certificados TLS para o Apache disponíveis em `certs/server.crt` e `certs/server.key` (ou configure variáveis para apontar outros caminhos). Opcionalmente, um arquivo de cadeia (`certs/ca.crt`).
4. (Opcional) Certificado da autoridade certificadora (`ca.crt`) emitente do MySQL caso a conexão precise usar TLS.

## Configuração

1. Copie o arquivo `.env.example` para `.env` e ajuste os valores das variáveis de ambiente de acordo com o seu ambiente:

   ```bash
   cp .env.example .env
   vim .env
   ```

   Principais variáveis:

   - `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_NAME`, `DATABASE_USER`, `DATABASE_PASSWORD`: apontam para o MySQL externo.
   - `MYSQL_SSL_CA`: caminho absoluto dentro do contêiner para o certificado da CA do MySQL (ex.: `/certs/ca.crt`). Deixe em branco para conexões sem TLS.
   - `APACHE_SSL_CERT_FILE`, `APACHE_SSL_KEY_FILE`, `APACHE_SSL_CHAIN_FILE`, `APACHE_SSL_REQUIRE_CUSTOM_CERT`: configuram o material TLS usado pelo Apache na porta 8443.

2. Se utilizar TLS no MySQL, copie o certificado da CA para o diretório `certs/` (ou outro local montado no contêiner) e informe o caminho na variável `MYSQL_SSL_CA`. Em cada cliente (Kali, navegadores etc.), importe o mesmo certificado de CA para que a validação ocorra sem alertas.

3. Garanta que o usuário configurado no `.env` possua permissão de leitura e escrita no banco selecionado. O script `script_sql.sql` pode ser executado manualmente no servidor MySQL para criar a estrutura inicial.

## Executando

Utilize o `docker-compose` para subir todos os serviços. O serviço `db_check` ficará em loop até que a porta `DATABASE_PORT` do host `DATABASE_HOST` esteja acessível.

```bash
docker-compose up --build
```

O serviço **web** utiliza o diretório do projeto como DocumentRoot. O portal web pode ser acessado exclusivamente em `https://localhost:8443` (ajuste o host conforme o ambiente). Apenas a porta 8443 é exposta; gateway, tickets e stats permanecem restritos à rede interna do Docker.

Para validar conectividade com o banco antes ou depois de subir os contêineres, execute o script de teste manual:

```bash
./scripts/test-db-conn.sh
```

Se desejar sobrescrever o host/porta temporariamente, utilize variáveis de ambiente ao chamar o script:

```bash
DATABASE_HOST=192.168.8.34 DATABASE_PORT=3306 ./scripts/test-db-conn.sh
```

### Configurando o certificado HTTPS

1. Gere ou obtenha um certificado válido para o host que responderá em `https://localhost:8443`.
   No pfSense, utilize a autoridade certificadora interna e exporte o certificado e a chave
   privada em formato PEM.
2. Salve os arquivos no diretório `certs/` da raiz do projeto como `server.crt` (cadeia ou
   fullchain) e `server.key`. Um arquivo de cadeia separado também pode ser informado via
   variável `APACHE_SSL_CHAIN_FILE`.
3. (Opcional) Ajuste o arquivo `.env` para apontar outros caminhos (ou liberar o uso de
   autoassinados), caso utilize nomes diferentes:

   ```env
   # Defina "true" se quiser bloquear o fallback para certificados autoassinados.
   APACHE_SSL_REQUIRE_CUSTOM_CERT=false
   APACHE_SSL_CERT_FILE=/certs/meu-certificado.pem
   APACHE_SSL_KEY_FILE=/certs/minha-chave.key
   APACHE_SSL_CHAIN_FILE=/certs/ca-intermediaria.pem
   ```

4. Suba os serviços novamente com `docker-compose up --build`. O script de inicialização
   detectará os arquivos e configurará o Apache automaticamente. Se estiver usando o
   modo estrito (`APACHE_SSL_REQUIRE_CUSTOM_CERT=true`) e algum arquivo estiver ausente,
   o contêiner do Apache encerrará com uma mensagem indicando os caminhos esperados
   (verifique com `docker-compose logs web`). Com o modo padrão (`false`), ele gerará
   um certificado autoassinado temporário para que você possa finalizar os testes.

Com essa configuração, os navegadores reconhecerão o certificado como confiável assim que o
certificado da autoridade emissora estiver instalado no ambiente.

### Observações sobre o MySQL externo

- phpMyAdmin não é mais provisionado neste compose para evitar exposição indevida na DMZ. Caso precise utilizá-lo, rode-o apenas na rede interna.
- Para administração manual, conecte-se diretamente ao servidor MySQL da rede interna (por exemplo, `mysql -h 192.168.8.34 -u app_user -p`).
- Certifique-se de liberar o host/porta no firewall para a rede onde os contêineres rodam.

## Endpoints

Ao acessar o endereço acima, você verá uma mensagem com os caminhos disponíveis.

- `https://localhost:8443/api/tickets.php` - proxy que expõe as operações do gateway pela porta segura
- `https://localhost:8443/api_stats.php` - endpoint HTTPS para o microserviço de estatísticas
  (internamente, ambos os scripts utilizam `http://gateway/` para chegar aos microserviços)
- `api/create_ticket.php` - proxy que envia o formulário de novo chamado ao gateway, evitando problemas de CORS.

## Verificando o gateway

Para acompanhar as requisições encaminhadas pelo gateway, execute:

```bash
docker-compose logs -f gateway
```

Cada requisição gera uma linha de log indicando o método, a rota recebida e o serviço interno escolhido.

## Segurança e Manutenção

O projeto suporta login local ou via Amazon Cognito (arquivos `cognito_login.php` e `auth_callback.php`).
Ao autenticar, um token JWT é gerado e armazenado na sessão. Esse token
é enviado no header `Authorization` para que o gateway repasse a
requisição aos microserviços.

Um script `backup_db.sh` está disponível para gerar backups da base MySQL. Execute-o a partir de uma máquina com acesso ao banco externo.
Há também o utilitário `sla_monitor.php` que dispara notificações antes do vencimento do SLA dos chamados.

Todos os acessos e ações relevantes são registrados na tabela `logs` do banco de dados, permitindo auditoria completa.
