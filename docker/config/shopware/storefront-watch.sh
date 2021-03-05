#!/usr/bin/env bash
set -e

while [ ! -f install.lock ]; do
    echo "storefront-watch: waiting for shopware init to finish..."
    sleep 15
done

./bin/watch-storefront.sh
echo "Storefront-watch is ready."
