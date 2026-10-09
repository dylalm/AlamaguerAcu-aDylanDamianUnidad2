#!/bin/sh
set -e

# Render asigna el puerto en la variable PORT
PORT="${PORT:-80}"
sed -i "s/Listen 80/Listen ${PORT}/" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/" /etc/apache2/sites-available/000-default.conf

# Base de datos SQLite para la demostración (en producción real: PostgreSQL)
mkdir -p database && touch database/database.sqlite
chown -R www-data:www-data storage bootstrap/cache database

php artisan config:cache
php artisan migrate --force

# Datos de ejemplo para la demostración (SEED_DEMO=true)
if [ "${SEED_DEMO:-false}" = "true" ]; then
  php artisan db:seed --force
fi

exec apache2-foreground