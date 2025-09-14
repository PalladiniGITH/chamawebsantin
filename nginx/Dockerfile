FROM owasp/modsecurity-crs:3.3-nginx
RUN apt-get update && apt-get install -y nmap netcat-openbsd && rm -rf /var/lib/apt/lists/*
COPY conf.d /etc/nginx/conf.d
RUN mkdir -p /var/log/nginx && chown -R nginx:nginx /var/log/nginx
