#!/bin/sh

host=$1

mkdir -p /tank/backups/hosts/$1

rsync -rav $host:/data/ /tank/backups/hosts/$1
