#!/bin/ash

for certname in $(cat /certs.txt); do
    echo $certname
    if [ -f /certificates/certificates/$certname.crt ]; then
        /lego --accept-tos --email pete@petekeen.net --dns.resolvers 8.8.8.8:53 --path /certificates --domains $certname --domains "*.${certname}" --dns route53 renew
    else
        /lego --accept-tos --email pete@petekeen.net --dns.resolvers 8.8.8.8:53 --path /certificates --domains $certname --domains "*.${certname}" --dns route53 run
    fi
done

set -e

wget -O - --post-data "" --header "Authorization: Bearer $GATUS_API_TOKEN" 'https://gatus.keen.land/api/v1/endpoints/infra_certificate-builder/external?success=true'
