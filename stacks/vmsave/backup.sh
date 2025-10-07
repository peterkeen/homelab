#!/bin/sh

set -e

timestamp=$(date +%Y%m%d%H%M%S)

pg_dump --username=vmsave vmsave | gzip --best --stdout > /backups/vmsave-dump-${timestamp}.gz

find /backups -type f -name '*.gz' -mtime +7 -exec rm {} \;
