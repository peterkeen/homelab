Keen.land Homeprod and Homelab
------------------------------

This repo contains the scripts and tools I use to manage my homelab and homeprod hosts.

In this scheme, hosts are running a single docker-compose app containing a configurable set of stacks.
Each host has an entry in `hosts.yml` that describes:

- the stacks it should be running
- any environment variables that should be set (copied to a `.env` file)
- optionally, one or more ansible groups that the host should belong to

In addition to docker, hosts have various other things running. For example, all of them
run CoreDNS on the host to proxy DNS to my NextDNS instance, along with forwarding queries for
my tailnet hosts to the MagicDNS resolver IP (MagicDNS taking over DNS on some hosts isn't really tenable).

This is what the other stuff does:

- `stacks/` contains the docker compose stacks
- `lib/` is where the code that interprets `hosts.yml` and drives the system lives
- `ansible/` contains the ansible playbooks that, among other things, deploys the stacks to the hosts

The code in `lib` is lightly typed with Sorbet.
Really I just wanted `T::Struct` to parse `hosts.yml`, there aren't any `sig`s and I don't bother with `srb`.

## How it works

`Rakefile` contains a `build` target that:

1. Loads `hosts.yml`
2. Gathers secrets from 1Password using the `op` command line tool
3. Renders any templated files that it finds (i.e. files ending in `.erb`)
4. Re-loads `hosts.yml`
5. Iterates over each host in the config and builds a directory to be rsync'd to the host

The `ansible` target runs all of the playbooks (via `playbooks/main.yaml`).
It can also be told to run a single playbook.

The only prerequisites for a host is to be on my tailnet.

## Compose extensions

I have several compose extensions that I use pretty frequently:

- `x-web` sets up a reverse proxy entry in the `local-proxy` config
- `x-op-item` see 'Secrets' below
- `x-backup` see 'Backups' below

By convention, my stacks put data in `/data/<stackname>` and I try to have them run as user `1000:1000` as much as possible.

## Networking

Each internally facing host that runs web applications runs the stack `local-proxy`. This stack has an automatically generated nginx config that:

1. Terminates HTTPS with a wildcard keen.land certificate
2. Forwards requests to a container running on the host.

DNS is configured (via `rake dns:apply` in `dns/`) to send traffic for the hostname associated with a container to the machine running that container. Thus, no overlay network necessary.

## Secrets

Secrets are stored in a hard-coded 1Password vault as secure notes. Each note has one or more plain text or password fields representing environment variables, where the field name is the variable name and the value is the variable value.

Secrets are made available to stacks via the `x-op-item` compose extension, which consists of an array of 1Password item UUIDs in the hard-coded secrets vault. When generating the deployable package for each server the system will merge all of the items for every service together in list order and write the resulting environment variables to a `.env` file alongside the stack's compose file.

## Backups

Backups are very simple. Each service can define a `x-backup` key that looks like this:

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

Cron on the host runs backups nightly.

## Health checks

Docker compose allows one to define health checks but doesn't do anything with them directly. I have set up a 5 minute cron that restarts any container in an unhealthy state. This lets me do things like, eg, restart the Waterfurnace MQTT gateway container automatically every 12 hours by making a healthcheck fail.

## Can I use this?

Probably don't. I don't have the bandwidth to help you so you're entirely on your own.

That said, I'm proud of some of the ideas and if you want to steal them for your own setup be my guest.

