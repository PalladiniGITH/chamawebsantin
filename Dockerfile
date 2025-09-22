FROM php:7.4-apache

# Apache servirá arquivos a partir do diretório padrão
ENV APACHE_DOCUMENT_ROOT /var/www/html

# Instalar dependências do sistema necessárias
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    openssl \
    && docker-php-ext-install zip

# Instala o driver mysqli e pdo_mysql
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Instalar o Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copia os arquivos do projeto para dentro do Apache
COPY . /var/www/html/

# Ativa o mod_rewrite do Apache (se necessário)
RUN a2enmod rewrite ssl headers && \
    a2ensite default-ssl && \
    sed -i 's#/etc/ssl/certs/ssl-cert-snakeoil.pem#/etc/ssl/certs/web.crt#' /etc/apache2/sites-available/default-ssl.conf && \
    sed -i 's#/etc/ssl/private/ssl-cert-snakeoil.key#/etc/ssl/private/web.key#' /etc/apache2/sites-available/default-ssl.conf && \
    sed -i 's#<VirtualHost _default_:443>#<VirtualHost *:8443>#' /etc/apache2/sites-available/default-ssl.conf && \
    a2dissite 000-default && \
    sed -i 's/^Listen 80/#Listen 80/' /etc/apache2/ports.conf && \
    sed -i 's/Listen 443/Listen 8443/g' /etc/apache2/ports.conf

COPY docker/apache/start-apache.sh /usr/local/bin/start-apache.sh
RUN chmod +x /usr/local/bin/start-apache.sh

# Instalar as dependências do Composer (se houver um composer.json)
WORKDIR /var/www/html
RUN if [ -f "composer.json" ]; then composer install --no-interaction; fi

# Dá permissão aos arquivos
RUN chown -R www-data:www-data /var/www/html

# Define o diretório de trabalho padrão
WORKDIR /var/www/html

EXPOSE 8443

CMD ["start-apache.sh"]
