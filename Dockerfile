# --- Builder stage: install composer and PHP dependencies in isolation
FROM php:7.4-cli AS builder
WORKDIR /app

# Install only the utilities required for composer in this throwaway stage
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    unzip \
    zip \
    libzip-dev \
  && rm -rf /var/lib/apt/lists/*

# Fetch composer without keeping the installer around
RUN php -r "copy('https://getcomposer.org/installer','composer-setup.php');" \
  && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
  && rm composer-setup.php

COPY composer.json composer.lock* /app/
RUN if [ -f composer.json ]; then composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader; fi

# Copy the rest of the application source and remove VCS metadata
COPY . /app
RUN rm -rf /app/.git

# Pre-create runtime-writable directories so they can be mounted as tmpfs later
RUN mkdir -p /app/uploads /app/tmp


# --- Runtime stage: lightweight Apache + PHP image without build tooling
FROM php:7.4-apache
ENV APACHE_DOCUMENT_ROOT /var/www/html

# Install runtime dependencies and PHP extensions, removing build libraries afterwards
# Keeping build tools out of the final image reduces the attack surface for shell escapes.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends libzip-dev openssl ca-certificates; \
    docker-php-ext-install zip mysqli pdo pdo_mysql; \
    apt-get purge -y --auto-remove libzip-dev; \
    rm -rf /var/lib/apt/lists/*

# Enable the necessary Apache modules and tailor the default TLS virtual host once at build time
RUN a2enmod rewrite ssl headers \
  && a2ensite default-ssl \
  && sed -i 's#/etc/ssl/certs/ssl-cert-snakeoil.pem#/run/apache2/web.crt#' /etc/apache2/sites-available/default-ssl.conf \
  && sed -i 's#/etc/ssl/private/ssl-cert-snakeoil.key#/run/apache2/web.key#' /etc/apache2/sites-available/default-ssl.conf \
  && sed -i 's#<VirtualHost _default_:443>#<VirtualHost *:8443>#' /etc/apache2/sites-available/default-ssl.conf \
  && sed -i 's/^Listen 80/#Listen 80/' /etc/apache2/ports.conf \
  && sed -i 's/Listen 443/Listen 8443/g' /etc/apache2/ports.conf \
  && sed -i '/<VirtualHost \*:/a \\n    IncludeOptional /run/apache2/cert-overrides.conf' /etc/apache2/sites-available/default-ssl.conf \
  && a2dissite 000-default

# Copy the prepared application from the builder stage
COPY --from=builder /app /var/www/html

# Install the hardened startup script
COPY --from=builder /app/docker/apache/start-apache.sh /usr/local/bin/start-apache.sh
RUN chmod +x /usr/local/bin/start-apache.sh

# Ensure Apache runs as www-data and files stay readable even when bind-mounted
# for development. Directories remain non-writable while files keep world-read
# permission so Apache can traverse and serve the application without tripping
# 403 errors when host ownership differs.
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && find /var/www/html -type d -exec chmod 755 {} \;

WORKDIR /var/www/html

EXPOSE 8443
CMD ["start-apache.sh"]
