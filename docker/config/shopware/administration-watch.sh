#!/usr/bin/env bash
set -e

while [ ! -f install.lock ]; do
    echo "administration-watch: waiting for shopware init script to finish..."
    sleep 15
done

./bin/watch-administration.sh
echo "Administration-watch is ready."
