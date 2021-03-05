#!/bin/bash
set -e

WORK_PATH="${PWD}/docker/shopware"
PLATFORM_PATH="${WORK_PATH}/platform"
SHOPWARE_VERSION="$1"

echo "Checking if local dependencies exist..."

if [ ! -d "${PLATFORM_PATH}" ]; then
	echo "Downloading dependencies to the local filesystem for debug purposes only..."
	mkdir $PLATFORM_PATH
	echo "${SHOPWARE_VERSION}"
	docker run --rm --interactive --network host \
 	--volume "${WORK_PATH}":/app:delegated \
 	--env COMPOSER_PROCESS_TIMEOUT=0 \
 	composer create-project --no-interaction --ignore-platform-reqs --no-scripts --prefer-dist -- shopware/platform ./platform "${SHOPWARE_VERSION}"
	echo "Done."
else
  echo "Directory ${PLATFORM_PATH} exists. Skipping..."
fi
