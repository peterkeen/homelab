FROM alpine:20250108 AS builder

WORKDIR /app

RUN wget https://github.com/selfhst/icons/archive/refs/heads/main.tar.gz && tar xzf main.tar.gz

FROM b4bz/homer:v25.11.1

COPY --from=builder /app/icons-main/svg /www/icons/svg