#!/usr/bin/env bash

set -e

touch ./public/media/shopware-init.lock

PATH="${PATH}:/usr/local/bin"
DB_USER=$(php -r 'echo parse_url(getenv("DATABASE_URL"), PHP_URL_USER);')
DB_PASS=$(php -r 'echo parse_url(getenv("DATABASE_URL"), PHP_URL_PASS);')
DB_HOST=$(php -r 'echo parse_url(getenv("DATABASE_URL"), PHP_URL_HOST);')
DB_PORT=$(php -r 'echo parse_url(getenv("DATABASE_URL"), PHP_URL_PORT);')
DB_NAME=$(php -r 'echo substr(parse_url(getenv("DATABASE_URL"), PHP_URL_PATH), 1);')

if [ -z "${DB_PORT}" ]; then
  DB_PORT="3306"
fi

bin/wait-for.sh ${DB_HOST}:${DB_PORT} -t 120
bin/wait-for.sh "${SHOPWARE_ES_HOSTS}" -t 120

SCHEMA_EXISTS=$(mysql -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASS} -N ${DB_NAME} -e "SHOW TABLES LIKE 'plugin';" | wc -l)

if [ "${SCHEMA_EXISTS}" == "0" ]; then
  echo "Empty database - initializing..."
  bin/console system:install --basic-setup --create-database
fi

# generate jwt secret only for a single instance docker version.
# A k8s pod should have it mounted from a secret.
if [ ${SHOPWARE_INIT} -eq 1 ] && [ ! -f "${PROJECT_ROOT}/config/jwt/private.pem" ]; then
  bin/console system:generate-jwt-secret
fi

bin/console database:migrate --all core
bin/console database:migrate-destructive --all core
bin/console scheduled-task:register
bin/console cache:clear --no-warmup
rm -f ./public/media/shopware-init.lock

echo "Shopware init successful."
