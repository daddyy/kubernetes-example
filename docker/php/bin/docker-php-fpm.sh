#!/usr/bin/env sh

DELAY=$1

if [ ! -n "$1" ]; then
    echo "Error: delay was not set" >&2
    exit 1
elif ! echo "$1" | grep -Eq '^[0-9]+$'; then
    echo "Error: delay is not a number" >&2
    exit 1
fi

if [ ! -f "/tmp/liveness-probe" ]; then
    echo "Error: liveness file not found: /tmp/liveness-probe" >&2
    exit 1
fi

CURRENT_TIME=$(date +%s)
FILE_MODIFY_TIME=$(stat -c %Y /tmp/liveness-probe)
DIFF=$((CURRENT_TIME - FILE_MODIFY_TIME))

if [ $DIFF -gt $DELAY ]; then
    echo "Error: liveness file /tmp/liveness-probe is older than $DELAY seconds." >&2
    exit 1
fi

exit 0
