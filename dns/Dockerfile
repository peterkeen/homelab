FROM ghcr.io/superfly/flyctl AS flyctl

FROM ghcr.io/stackexchange/dnscontrol:4.21.0

RUN apk update && apk add --no-cache kubectl ruby && gem install rake

WORKDIR /app

ADD Rakefile.docker /app/Rakefile
ADD shared_tasks.rb /app/shared_tasks.rb

ADD dnsconfig.js /app/dnsconfig.js

ADD creds.json.ci /app/creds.json

COPY --from=flyctl /flyctl /
COPY --from=flyctl /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs

ENTRYPOINT ["rake"]

