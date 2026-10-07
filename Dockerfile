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

# 3) Imagen final: PHP + Apache
FROM php:8.3-apache
RUN apt-get update \
 && apt-get install -y --no-install-recommends libpq-dev libzip-dev libsqlite3-dev unzip \
 && docker-php-ext-install pdo_pgsql pdo_sqlite zip opcache \
 && a2enmod rewrite \
 && rm -rf /var/lib/apt/lists/*

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
 && echo 'SetEnvIf X-Forwarded-Proto "https" HTTPS=on' > /etc/apache2/conf-available/proxy-https.conf \
 && a2enconf proxy-https

WORKDIR /var/www/html
COPY --from=assets /app /var/www/html
COPY docker/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 80
CMD ["start.sh"]
