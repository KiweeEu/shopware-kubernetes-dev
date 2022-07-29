#!/usr/bin/env bash

set -e

if [[ "${SHOPWARE_INIT}" == "1" ]]; then
  ./bin/shopware-init.sh
fi

# Show the maintenance page instead of the installer during startup.
rm -f install.lock
# cp public/maintenance.html public/recovery/install/index.php

PATH="${PATH}:/usr/local/bin"
DB_USER=$(php -r 'echo parse_url(getenv("DATABASE_URL"), PHP_URL_USER);')
DB_PASS=$(php -r 'echo parse_url(getenv("DATABASE_URL"), PHP_URL_PASS);')
DB_HOST=$(php -r 'echo parse_url(getenv("DATABASE_URL"), PHP_URL_HOST);')
DB_PORT=$(php -r 'echo parse_url(getenv("DATABASE_URL"), PHP_URL_PORT);')
DB_NAME=$(php -r 'echo substr(parse_url(getenv("DATABASE_URL"), PHP_URL_PATH), 1);')

if [ -z "$DB_PORT" ]; then
  DB_PORT="3306"
fi

bin/wait-for.sh ${DB_HOST}:${DB_PORT} -t 120
bin/wait-for.sh "${SHOPWARE_ES_HOSTS}" -t 180

SCHEMA_EXISTS=$(mysql -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASS} -N ${DB_NAME} -e "SHOW TABLES LIKE 'plugin';" | wc -l)

if [ "$SCHEMA_EXISTS" == "0" ]; then
  echo "The database is empty!"
  exit 254
fi

bin/console plugin:refresh
bin/console assets:install
bin/console theme:compile

while [ -f "./public/media/shopware-init.lock" ]; do echo 'Waiting for shopware-init job to complete...'; sleep 2; done

touch install.lock

echo "Shopware 6 boot finished."
