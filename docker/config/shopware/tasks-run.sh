#!/usr/bin/env bash

set -e

while [ ! -f install.lock ]; do
    echo "scheduled-task:run waiting for shopware-init script to finish..."
    sleep 15
done

bin/console scheduled-task:run --memory-limit=512M --time-limit=295 -vv
