ARG ALPINE_VERSION=3.10
ARG RUBY_VERSION=2.6.6

# Defines base image which builder and final stage use
FROM ruby:2.3.1-slim as base

# Change this if Gemfile.lock bundler version changes
ARG BUNDLER_VERSION=2.2.17

RUN apt-get add --update \
    tzdata \
    git \
    nodejs \
    # && rm -rf /var/cache/apk/* \
    && gem install bundler:$BUNDLER_VERSION \
    && bundle config --global frozen 1

FROM base as builder

RUN apt-get add --update build-base

WORKDIR /usr/src/app
COPY . .

RUN bundle config set --local without 'development' \
  && bundle install \
  && RAILS_ENV=production bundle exec rake assets:precompile \
  && mkdir -p 777 /usr/src/app/coverage

# Start a new build stage to minimise the final image size
FROM base

RUN addgroup -S app && adduser -S -G app app
EXPOSE 3000

WORKDIR /usr/src/app

COPY --from=builder --chown=app /usr/local/bundle /usr/local/bundle
COPY --from=builder --chown=app /usr/src/app     ./app

USER app

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /app
ENTRYPOINT ["sh", "/app/entrypoint.sh"]
