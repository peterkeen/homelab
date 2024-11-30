# Stacks

## `int-proxy`

To generate certificate the first time:

```sh
docker exec -it dockerstack-root /app/start.sh run lego --dns.resolvers 8.8.8.8:53 --domains keen.land --domains '*.keen.land' --email 'pete@petekeen.net' --dns route53 run
```
