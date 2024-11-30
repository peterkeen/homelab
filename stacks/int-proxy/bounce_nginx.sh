#!/bin/sh

set -e

printf "POST /containers/int-proxy/restart HTTP/1.1\nHost: v1.24\nAccept: */*\n\n" | nc local:/var/run/docker.sock
