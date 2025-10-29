#!/bin/ash

if [ ! -d /transcodes ]; then
    exit 0
fi

find /transcodes -mmin +119 -type f -exec rm -fv {} \;

