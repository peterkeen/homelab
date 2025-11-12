Caddy Config
------------

Two stages:

# Stage 1: HTTPS Termination

- listen on 80 and 443
- redirect 80 to 443
- terminate tls
  - use pre-built certificates
- two options for next steps:
  - proxy to anubis (if `anubis == true`)
  - proxy to stage 2 (if `anubis == false`)

# Stage 2: Upstream

- listen on unix socket
- three options:
  - redirect to canonical hostname
  - proxy to local upstream (if route target running locally)
  - proxy to remote upstream (if route requests public ingress)

# Anubis

- listen on unix socket
- proxy to stage 2
