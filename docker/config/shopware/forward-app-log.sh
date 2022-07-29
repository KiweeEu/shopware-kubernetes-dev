#!/usr/bin/env bash
set -e

FILE_NAME=$1

if [ "${FILE_NAME}" == "" ]; then
  echo "Usage: forward-app-log.sh log-file-name-without-extension"
  exit 1
fi

FILE_PATH="./var/log/${FILE_NAME}.log"

# Create the log file if doesn't exist.
touch $FILE_PATH

# Print the log with a prefix for easier separation.
tail -f $FILE_PATH | sed -E 's/^(.+)$/\[log:'"${FILE_NAME}"'\]\1/'
