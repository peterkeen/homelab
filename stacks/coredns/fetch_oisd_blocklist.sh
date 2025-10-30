#!/bin/ash

set -e

curl https://big.oisd.nl/unbound > /data/unbound/oisd_big.conf

docker restart unbound

if [[ ! -z "$GATUS_AUTH_TOKEN" ]]; then
    curl -XPOST -H "Authorization: Bearer ${GATUS_AUTH_TOKEN}" "https://gatus.keen.land/api/v1/endpoints/unbound-blocklist-sync_${HOSTNAME}/external?success=true"
fi
