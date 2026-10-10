#!/bin/sh
set -e

# El proveedor de hosting asigna el puerto en la variable PORT
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

# mod_php solo funciona con el MPM prefork: se deja ese y se quitan los demás
for f in /etc/apache2/mods-enabled/mpm_*; do
  case "$f" in
    *mpm_prefork.*) ;;
    *) rm -f "$f" ;;
  esac
done
a2enmod mpm_prefork >/dev/null 2>&1 || true

echo "MPM activos en /etc/apache2/mods-enabled:"
ls /etc/apache2/mods-enabled | grep '^mpm_' || true
apache2ctl -M 2>&1 | grep -i mpm || true

exec apache2-foreground