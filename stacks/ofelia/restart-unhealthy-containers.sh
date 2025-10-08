#!/bin/sh

set -e
set -o pipefail

# Get a list of unhealthy containers
unhealthy_containers=$(docker ps -q -f health=unhealthy)

# Loop through the unhealthy containers and restart them
for container_id in $unhealthy_containers; do
  echo "Restarting unhealthy container: $container_id"
  docker restart $container_id
done
