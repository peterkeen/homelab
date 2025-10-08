# Fly Proxy

This sets up a simple nginx caching proxy on Fly.io. The twist is that it uses Tailscale to proxy things from a server in my basement.

My motivation for writing this is to stop using my [diy cdn](https://github.com/peterkeen/diycdn). It was a fun learning experience but it's caused a number of headaches for me and it's a bunch of moving pieces that I don't want to have to maintain anymore.

Key points

* Use basic standard hand-written nginx config. Nothing generated.
* Use Docker-provided base `nginx` image. Nothing hand-built.
* Leverage fly.io for TLS termination and global anycast distribution
* Use Tailscale to my home machines instead of zerotier
* No active rails app to manage
* No additional VPSs to manage
* No complicated DNS setup
