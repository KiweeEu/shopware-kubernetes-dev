#!/usr/bin/env bash
set -e

while [ ! -f install.lock ]; do
    echo "storefront-watch: waiting for shopware init to finish..."
    sleep 15
done

./bin/build-storefront.sh
./bin/watch-storefront.sh
