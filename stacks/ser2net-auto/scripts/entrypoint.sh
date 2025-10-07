#!/bin/bash

set -e
set -x
set -o pipefail

echo "Generating ser2net.yaml"

mkdir -p /etc/ser2net
./discover.sh > /etc/ser2net/ser2net.yaml

echo "Running ser2net"

exec ser2net -d -l -c /etc/ser2net/ser2net.yaml
