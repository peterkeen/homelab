#!/bin/sh

echo "Clearing cache"

set -e

mkdir -p /cache/nginx
chmod 777 /cache/nginx

rm -rf /cache/nginx/*

echo "Cache cleared"
