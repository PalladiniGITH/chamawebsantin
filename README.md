# chamawebrest

Este projeto demonstra uma arquitetura simples de microserviços em PHP. Os serviços comunicam-se através de APIs REST e um API Gateway centraliza o acesso externo.

## Serviços

- **gateway**: expõe as rotas públicas e encaminha as requisições para os microserviços internos.
- **tickets**: responsável pelo gerenciamento de chamados.
- **stats**: fornece estatísticas agregadas usadas na página de relatórios.
- **db**: banco de dados MySQL compartilhado entre os serviços.
- **shared/connect.php**: script único de conexão ao banco utilizado pelos serviços.
- **front-end**: arquivos PHP e recursos estáticos servidos na raiz do projeto.

## Executando

Utilize o `docker-compose` para subir todos os serviços. O script `script_sql.sql` 
será executado automaticamente no primeiro start do banco, populando a tabela de
exemplo com um usuário administrador.

Credenciais padrão: `admin@sistema.com` / `admin123` (armazenada como hash SHA-256).

```bash
docker-compose up --build
```

O serviço **web** utiliza o diretório do projeto como DocumentRoot. O arquivo `index.php` exibe a página de login.

O portal web pode ser acessado exclusivamente em `https://localhost:8443`.
O Apache está configurado somente para HTTPS e a porta 80 foi desabilitada no contêiner,
garantindo que a máquina host exponha apenas a porta 8443.

Para evitar o alerta de "conexão não segura", coloque um certificado emitido por uma
autoridade confiável nos arquivos `certs/server.crt` e `certs/server.key` antes de
executar o `docker-compose up`. O contêiner copia automaticamente o material
personalizado durante a inicialização e, por padrão, **interrompe a inicialização caso
não encontre os arquivos**, evitando que um certificado autoassinado apareça por
engano. Caso você utilize o pfSense, emita o certificado pelas autoridades internas,
exporte-o em formato PEM e distribua o certificado da CA para o Kali e demais
navegadores do laboratório, garantindo que eles reconheçam o cadeado HTTPS sem avisos.
Se precisar utilizar um certificado autoassinado apenas em um ambiente de testes,
defina `APACHE_SSL_REQUIRE_CUSTOM_CERT=false` no `.env` para permitir a geração
automática.

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
   # Defina "false" apenas se quiser que o contêiner aceite gerar um certificado de testes.
   APACHE_SSL_REQUIRE_CUSTOM_CERT=true
   APACHE_SSL_CERT_FILE=/certs/meu-certificado.pem
   APACHE_SSL_KEY_FILE=/certs/minha-chave.key
   APACHE_SSL_CHAIN_FILE=/certs/ca-intermediaria.pem
   ```

4. Suba os serviços novamente com `docker-compose up --build`. O script de inicialização
   detectará os arquivos e configurará o Apache automaticamente. Se algum arquivo
   estiver ausente, o contêiner do Apache encerrará com uma mensagem indicando os
   caminhos esperados (verifique com `docker-compose logs web`).

Com essa configuração, os navegadores reconhecerão o certificado como confiável assim que o
certificado da autoridade emissora estiver instalado no ambiente.

### Como usar no Docker / Apache

No `docker-compose.yml` monte `./certs`:

```yaml
services:
  web:
    build: .
    ports:
      - "8443:8443"
    volumes:
      - ./certs:/certs:ro
```

No Apache (exemplo `/etc/apache2/sites-available/000-default-le-ssl.conf`):

```apache
<VirtualHost *:8443>
  ServerName 192.168.8.66

  SSLEngine on
  SSLCertificateFile /certs/server.crt
  SSLCertificateKeyFile /certs/server.key
  # se tiver chain separado:
  # SSLCertificateChainFile /certs/ca.crt

  # Segurança TLS mínima recomendada
  SSLOpenSSLConfCmd Protocol -ALL +TLSv1.2 +TLSv1.3
  Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
  Header always set X-Content-Type-Options "nosniff"
  Header always set X-Frame-Options "DENY"

  DocumentRoot /var/www/html
</VirtualHost>
```

Rebuild e up:

```bash
docker-compose up --build -d
```

O API Gateway, o banco de dados e os demais microserviços permanecem acessíveis apenas
pela rede interna do Docker, utilizando os nomes dos serviços (`gateway`, `tickets`, `stats` e `db`).
Para fazer login utilize `https://localhost:8443/`.

## Endpoints

 Ao acessar o endereço acima, você verá uma mensagem com os caminhos disponíveis.

 - `https://localhost:8443/api/tickets.php` - proxy que expõe as operações do gateway pela porta segura
 - `https://localhost:8443/api_stats.php` - endpoint HTTPS para o microserviço de estatísticas
   (internamente, ambos os scripts utilizam `http://gateway/` para chegar aos microserviços)
 - `api/create_ticket.php` - proxy que envia o formulario de novo chamado ao gateway, evitando problemas de CORS.

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

Um script `backup_db.sh` está disponível para gerar backups da base MySQL. Você pode agendar sua execução diária via cron. Há também o utilitário `sla_monitor.php` que dispara notificações antes do vencimento do SLA dos chamados.

Caso precise interagir diretamente com o banco, utilize o cliente MySQL dentro do contêiner (nenhuma porta do MySQL é publicada na máquina host; o contêiner do phpMyAdmin também permanece acessível apenas internamente):

```bash
docker-compose exec db mysql -u root -p
```

Todos os acessos e ações relevantes são registrados na tabela `logs` do banco de dados, permitindo auditoria completa.


