# 1) Dependencias PHP
FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --ignore-platform-reqs
COPY . .
RUN composer dump-autoload --optimize --no-dev --ignore-platform-reqs

# 2) Compilación de assets (Vite); necesita vendor por Ziggy
FROM node:20-alpine AS assets
WORKDIR /app
COPY --from=vendor /app /app
RUN npm ci && npm run build

# 3) Imagen final: PHP con su servidor integrado (sin Apache)
FROM php:8.3-cli
RUN echo "=== DIAGNOSTICO ===" \
 && php -v \
 && if command -v apache2 >/dev/null 2>&1; then \
      echo "APACHE ENCONTRADO"; apache2 -v; \
    else \
      echo "APACHE NO ESTA INSTALADO"; \
    fi \
 && echo "=== FIN DEL DIAGNOSTICO ==="

WORKDIR /var/www/html
COPY --from=assets /app /var/www/html
COPY docker/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 8080
CMD ["start.sh"]