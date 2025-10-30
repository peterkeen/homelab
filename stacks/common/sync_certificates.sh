#!/bin/ash

set -e

chmod 600 /configs/common/backup_key

rsync -e "ssh -i /configs/common/backup_key -o StrictHostKeyChecking=no" -rav hbackup@10.73.95.84:/mnt/tank/backups/hosts/lrrr-docker/data/certificates/ /data/certificates

chown -R root:root /data/certificates
chmod 644 /data/certificates/certificates/*

tar -C / -cf - /data/certificates/certificates/ | sha256sum | cut -d' ' -f1 > /data/certificates/certs.sum

if [[ ! -z "$GATUS_AUTH_TOKEN" ]]; then
    curl -XPOST -H "Authorization: Bearer ${GATUS_AUTH_TOKEN}" "https://gatus.keen.land/api/v1/endpoints/certificate_sync_${HOSTNAME}/external?success=true"
fi
