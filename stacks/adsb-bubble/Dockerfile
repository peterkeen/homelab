FROM alpine:3 AS builder

RUN apk add --no-cache ruby ruby-bundler ruby-dev ca-certificates build-base

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

FROM alpine:3

RUN apk add --no-cache ruby ruby-bundler ca-certificates

COPY --from=builder /usr/lib/ruby/gems /usr/lib/ruby/gems

COPY . .

CMD ["ruby", "run.rb"]