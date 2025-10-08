#!/bin/bash

tar --sort=name -C / -cf - /etc/nginx /etc/letsencrypt/certificates | sha256sum | cut -d' ' -f1 > /etc/nginx-sha
