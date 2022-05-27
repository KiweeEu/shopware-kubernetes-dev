#!/usr/bin/env bash

set -e

while [ ! -f install.lock ]; do
    echo "messenger:consume waiting for shopware-init script to finish..."
    sleep 15
done

/usr/local/bin/php -d memory_limit=2G bin/console messenger:consume --time-limit=295 -vv
