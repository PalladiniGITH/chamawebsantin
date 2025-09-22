FROM php:8.4.13RC1-cli
RUN docker-php-ext-install pdo pdo_mysql
WORKDIR /app
# Copia apenas os arquivos do gateway e o diretório compartilhado
COPY services/gateway/ /app/
COPY shared/ /app/shared/
CMD ["php", "-S", "0.0.0.0:80", "-t", "/app"]
