#!/bin/ash

if [ ! -d /cache/transcodes ]; then
    exit 0
fi

find /cache/transcodes -mmin +119 -type f -exec rm -fv {} \;
