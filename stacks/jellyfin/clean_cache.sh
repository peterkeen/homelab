#!/bin/ash

if [ ! -d /cache/transcodes ]; then
    exit 0
fi

while true; do
    find /cache/transcodes -mmin +119 -type f -exec rm -fv {} \;
    sleep 60
done
