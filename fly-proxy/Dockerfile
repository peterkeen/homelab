FROM nginx:stable

WORKDIR /app

RUN apt-get update && apt-get install -y ca-certificates

COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscaled /usr/local/bin
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscale /usr/local/bin

COPY proxy.conf /etc/nginx/conf.d/proxy.conf
COPY block.conf /etc/nginx/block.conf
COPY 00-start-tailscale.sh /docker-entrypoint.d
COPY 40-clear-cache.sh /docker-entrypoint.d
