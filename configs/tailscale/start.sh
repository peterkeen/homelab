#!/bin/ash
echo "Starting TS daemon"
tailscaled &
sleep 3
echo "Connecting to network"
tailscale up --auth-key $TS_AUTHKEY
