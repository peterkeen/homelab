Keen.land Homeprod and Homelab
------------------------------

This repo contains the scripts and tools I use to manage my homelab and homeprod hosts.

In this scheme, hosts are running a single docker-compose app containing a configurable set of stacks.
Each host has an entry in `hosts.yml` that describes:

- the stacks it should be running
- any environment variables that should be set (copied to a `.env` file)
- the local IP that we should use for DNS

## How it works

`Rakefile` contains an `apply` target that:

1. Loads `hosts.yml`
2. Gathers secrets from 1Password using the `op` command line tool

For each host, `composer.rb` does the following:

1. Copies stacks into a host-specific build directory
2. Renders any templated files that it finds (i.e. files ending in `.erb`)
3. Generates a `.env` file for the host as well as one for each stack, invoking hooks when needed
4. Generates a "stage zero" Docker compose file listing out all of the stacks as `include`s
5. Generates a `compose.override.yml` file that by default just sets up network aliases. Hooks can add to overrides.
5. Generates a "stage one" Docker compose file by running stage zero through `docker compose config`. Hooks can modify the "stage one" docker compose.
6. `rsync`s stacks (minus `docker-compose.yml`, `.env`, and any `.erb` files) to the remote host
7. Invokes any hooks that want to do something prior to deploy (i.e. upload files from the secrets store)
9. Sets `DOCKER_HOST=ssh://root@remote-host` and then runs `docker compose up` with the stage one compose file

The various compose files and secrets are only ever held in memory, they are never written to disk.

The only prerequisites for a host is to be on my tailnet.

## Compose extensions

I have several compose extensions that I use pretty frequently:

- `x-web` sets up a reverse proxy entry in the `local-proxy` config
- `x-op-item` feeds secrets to services
- `x-backup` backs up parts of the data directory
- `x-cron` see 'Cron' below

By convention, my stacks put data in `/data/<stackname>` and I try to have them run as user `1000:1000` as much as possible.

## Networking

Each internally facing host that runs web applications (as determined by the presence of the `x-web` extension) runs the stack `local-proxy`. This stack has an automatically generated nginx config that:

1. Terminates HTTPS with a wildcard keen.land certificate
2. Forwards requests to a container running on the host.

The `web_conf` hook handles setting up a network configuration for each web service on the `local-web` network with an alias of `service_name.stack_name.local-web.internal`. 

Local DNS is handled by CoreDNS and Unbound running on two hosts. Omada is configured to proxy all DNS traffic to those two machines. The CoreDNS configuration builds a hosts file for keen.land and serves that directly, and Unbound serves as a recursor and blocklist handler.

We currently use the [OISD](https://oisd.nl) "Big" blocklist.

Other DNS records are handled with dnscontrol in the `dns/` directory.

## Secrets

The `one_password` hook handles setting up secrets. Secrets are stored in a hard-coded 1Password vault as secure notes. Each note has one or more plain text or password fields representing environment variables, where the field name is the variable name and the value is the variable value.

Secrets are made available to stacks via the `x-op-item` compose extension, which consists of an array of 1Password item UUIDs in the hard-coded secrets vault. When generating the deployable package for each server the system will merge all of the items for every service together in list order and write their obfuscated references to a `.env` file alongside the stack's compose file.

In addition, `x-op-item` can be used to write a specific field from a 1Password item to a file on the remote machine with this syntax:

```
x-op-items:
  - ref: someitemuuid/field_name
    remote_path: /some/path/on/remote/host
```

## Backups

Each service can define a `x-backup` key that looks like this:

```
x-backup:
  prepare:
    - some-script-to-run-in-the-container.sh
  paths:
    - /host/path/to/back/up
    - /another/host/path
```

Paths defined in `paths` will be syned with `rsync --relative --dirs --archive --recursive` to the `/mnt/backups/hosts/<hostname>` directory on the NAS.

Prepare scripts are run inside the container prior to rsync and are expected to write to a path defined in `paths`. Output and exit stats are ignored.

Backups run nightly.

## Cron

Services can optionally declare `x-cron`, which is a list of cron definitions fed to [`ofelia`](https://github.com/mcuadros/ofelia). Crons run in the context of the container that they are defined within. Example:

```
x-cron:
  - name: "some job"
    schedule: "0 * * * * *" # every minute. IMPORTANT: ofelia requires a seconds column in the schedule
    command: "/some-script.sh"
```

## Health checks

Docker compose allows one to define health checks but doesn't do anything with them directly. I have set up a 5 minute cron that restarts any container in an unhealthy state. This lets me do things like, eg, restart the Waterfurnace MQTT gateway container automatically every 12 hours by making a healthcheck fail.

## Can I use this?

Probably don't. I don't have the bandwidth to help you so you're entirely on your own.

That said, I'm proud of some of the ideas and if you want to steal them for your own setup be my guest.

