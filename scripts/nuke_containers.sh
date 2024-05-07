#!/bin/bash

set -eo pipefail

hosts=$@

for host in $hosts; do
    echo $host
    ssh -t root@$host.corp.keen.land 'ash -c '\''docker kill $(docker ps -a -q) && docker system prune -a -f'\'''
done
