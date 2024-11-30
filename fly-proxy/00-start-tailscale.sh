#!/bin/sh

/usr/local/bin/tailscaled --state=mem: &
/usr/local/bin/tailscale up --auth-key=${TS_OAUTH_CLIENT_SECRET}?ephemeral=true\&preauthorized=true --advertise-tags=tag:fly-proxy --hostname=${FLY_APP_NAME}-${FLY_REGION}-${HOSTNAME}
