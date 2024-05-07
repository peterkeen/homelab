Keen.land Homeprod and Homelab
------------------------------

This repo contains the scripts and tools I use to manage my homelab and homeprod hosts.

In this scheme, hosts are running a single docker-compose app containing a configurable set of stacks.
Each host has an entry in `hosts.yml` that describes:

- the stacks it should be running
- the configs that should be copied to the host
- any environment variables that should be set (copied to a `.env` file)
- optionally, one or more ansible groups that the host should belong to

In addition to docker, hosts have various other things running. For example, all of them
run CoreDNS on the host to proxy DNS to my NextDNS instance, along with forwarding queries for
my tailnet hosts to the MagicDNS resolver IP (MagicDNS taking over DNS on some hosts isn't really tenable).

This is what the other stuff does:

- `stacks/` contains the docker compose stack files
- `configs/` contains various config files for the stacks
- `lib/` is where the code that interprets `hosts.yml` and drives the system lives
- `playbooks/` contains the ansible playbooks that, among other things, deploys the stacks to the hosts

The code in `lib` is lightly typed with Sorbet.
Really I just wanted `T::Struct` to parse `hosts.yml`, there aren't any `sig`s and I don't bother with `srb`.

## How it works

`Rakefile` contains a `build` target that:

1. Loads `hosts.yml`
1. Gathers secrets from 1Password using the `op` command line tool
2. Generates a Tailscale auth key using an OAuth credential found in 1Password
3. Renders any templated files that it finds (i.e. files ending in `.erb`)
4. Re-loads `hosts.yml`
5. Iterates over each host in the config and builds a directory to be rsync'd to the host

The `ansible` target runs all of the playbooks (via `playbooks/main.yaml`).
It can also be told to run a single playbook.

The only prerequisites for a host is to be on my tailnet.
Stacks generally put data in `/data` so that's also a soft prereq for my particular compose setup.

## Compose extensions

I have two compose extensions that I use pretty frequently:

- `x-web` sets up a reverse proxy entry in my `int-proxy` config
- `x-tailscale` sets up a [`tsnsrv`](https://github.com/boinkor-net/tsnsrv) proxy sidecar to put individual containers on my tailnet with automatic https

By convention, my stacks put data in `/data/<stackname>` and I try to have them run as user `1000:1000` as much as possible.

## Secrets

I have a vault dedicated to lab secrets.
In that vault are two kinds of items, Servers and Secure Notes. 
Each host has a Server item named with it's hostname and tagged, generally, with `server` and it's hostname.

Each Secure Note is a set of secrets and is tagged with the same taxonomy. 
Secrets consist of a Text entry where the name is the environment variable to set and the value is the secret itself.

Much time was spent making secret loading as fast as possible because the `op` command can be pretty slow.
It uses a trick that passes the results of one `op` invocation (effectively, "give me all the ids for secrets of categories X,Y") and pipes it to another `op` invocation that then fetches the contents of those items.

