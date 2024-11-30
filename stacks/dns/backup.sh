#!/bin/sh

set -eo pipefail

mkdir -p /etc/dns/config/backups
cd /etc/dns/config/backups

now=$(date +%s)

wget -o "$now.zip" "http://localhost:5380/api/settings/backup?token=$TECHNITIUM_API_TOKEN&blockLists=true&scopes=true&apps=true&stats=true&zones-true&allowedZones=true&blockedZones=true&dnsSettings=true&logSettings=true&authConfig=true"

# delete all but the most recent 7 backups
ls -tp *.zip | grep -v '/$' | tail -n +7 | tr '\n' '\0' | xargs -0 rm --
