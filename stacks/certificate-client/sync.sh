#!/bin/ash

set -e

rsync -e "ssh -i /backup_key -o StrictHostKeyChecking=no" -rav hbackup@10.73.95.84:/mnt/tank/backups/hosts/lrrr-docker/data/certificates/ /certificates

chown -R root:root /certificates
chmod 644 /certificates/certificates/*

tar -C / -cf - /certificates/certificates/ | sha256sum | cut -d' ' -f1 > /certificates/certs.sum
