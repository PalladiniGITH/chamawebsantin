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
garantindo que a máquina host exponha apenas a porta 8443. O navegador exibirá um aviso
de conexão não segura por se tratar de um certificado autoassinado; aceite o risco para
prosseguir nos testes locais.

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


