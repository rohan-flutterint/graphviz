#!/usr/bin/env bash

# Timestamp-prefix output from a given command. Usage:
#
#   my-command 2>&1 | timestamp.sh

while read line; do
  printf '[%s] %s\n' "$(date)" "${line}"
done
