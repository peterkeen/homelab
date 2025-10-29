#!/bin/bash

set -e
set -o pipefail

old_sha=$(cat /etc/nginx-sha)
new_sha=$(tar --sort=name -C / -cf - /etc/nginx /etc/letsencrypt/certificates | sha256sum | cut -d' ' -f1)

if [[ "$old_sha" != "$new_sha" ]]; then
    echo "Reloading nginx due to config change"
    echo $new_sha > /etc/nginx-sha
    nginx -s reload
fi
