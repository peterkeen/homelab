#!/bin/bash

set -e
set -x
set -o pipefail

env

BAUDMODE=${BAUDMODE:-115200n81}

DEVNODE=""
for i in {0..9}; do
    name="UDEV_DEVNODE_${i}"
    if [[ ! -z "${!name}" ]]; then
        DEVNODE="${!name}"
        break
    fi
done

if [[ -z "${DEVNODE}" ]]; then
    echo "Could not detect UDEV_DEVNODE"
    exit 1
fi

SNIPPET=$(
cat <<EOF    
connection: &connection
  accepter: tcp,6639
  connector: serialdev,$DEVNODE,$BAUDMODE,local
  options:
    kickolduser: true
EOF
             )

echo "Generating ser2net.yaml"

mkdir -p /etc/ser2net
echo "$SNIPPET" >> /etc/ser2net/ser2net.yaml

echo "Running ser2net"

exec ser2net -d -l -c /etc/ser2net/ser2net.yaml
