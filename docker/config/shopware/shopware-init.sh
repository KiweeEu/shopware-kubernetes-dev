#!/usr/bin/env bash
set -e

rm -f install.lock

sleep 5
bin/wait-for-it.sh -h db -p 3306 -t 1200
# wait a moment until init scripts are finished
sleep 20

DB_USER=$(php -r 'echo parse_url(getenv("DATABASE_URL"), PHP_URL_USER);')
DB_PASS=$(php -r 'echo parse_url(getenv("DATABASE_URL"), PHP_URL_PASS);')
DB_HOST=$(php -r 'echo parse_url(getenv("DATABASE_URL"), PHP_URL_HOST);')
DB_NAME=$(php -r 'echo substr(parse_url(getenv("DATABASE_URL"), PHP_URL_PATH), 1);')
SCHEMA_EXISTS=$(mysql -h${DB_HOST} -u${DB_USER} -p${DB_PASS} -N ${DB_NAME} -e "SHOW TABLES LIKE 'plugin';" | wc -l)

if [ "$SCHEMA_EXISTS" == "0" ]; then
    echo "Empty database - initializing..."
    bin/console system:install --basic-setup --create-database
fi

bin/console database:migrate --all core
bin/console database:migrate-destructive --all core
bin/console dal:refresh:index
bin/console scheduled-task:register
bin/console plugin:refresh
bin/console theme:refresh
bin/console bundle:dump
bin/console theme:dump
bin/console feature:dump
bin/console system:generate-jwt-secret
bin/console assets:install
bin/console theme:compile
bin/console cache:clear --no-warmup

touch install.lock