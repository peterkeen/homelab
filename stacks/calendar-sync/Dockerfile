FROM golang:1.23 AS build

# Set destination for COPY
WORKDIR /app

# Download Go modules
COPY go.mod go.sum ./
RUN go mod download

# Copy the source code. Note the slash at the end, as explained in
# https://docs.docker.com/reference/dockerfile/#copy
COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o calendar-sync

# Release

FROM alpine:edge

WORKDIR /app

COPY --from=build /app/calendar-sync .

RUN apk --no-cache add ca-certificates tzdata s6-portable-utils

CMD ["s6-pause"]