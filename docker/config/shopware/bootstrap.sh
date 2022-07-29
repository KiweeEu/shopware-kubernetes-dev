#!/usr/bin/env bash
set -e
set -x

./bin/shopware-boot.sh
/usr/bin/supervisord
