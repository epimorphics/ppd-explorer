ARG RUBY_VERSION=3.4.9
ARG ALPINE_VERSION=3.22
ARG BUNDLER_VERSION=2.7.2

# Defines base image which builder and final stage use
FROM ruby:$RUBY_VERSION-alpine$ALPINE_VERSION AS base

ENV DIR=/usr/src/app

RUN apk add --update --no-cache \
    bash \
    coreutils \
    git \
    nodejs \
    tzdata \
    && gem update --system

# for Bundler
ARG BUNDLER_VERSION
RUN echo "Bundler version ${BUNDLER_VERSION}"
RUN gem install bundler:$BUNDLER_VERSION
# installs the required gems
FROM base AS gems
RUN apk add --update build-base yaml-dev && gem update --system

COPY bin bin
COPY Gemfile Gemfile.lock .ruby-version ./
# .bundle/config contains the information required to access rubygems.pkg.github.com/epimorphics/
COPY .bundle/config /root/.bundle/config
RUN bundle config set --local without 'development test' \
    && bundle config set --local frozen 1 \
    && bundle install

# runs build to compile assets
FROM base AS builder
RUN apk add --update build-base && gem update --system

WORKDIR ${DIR}
# Copy the builds from the previous stages
COPY --from=gems --chown=app /usr/local/bundle /usr/local/bundle

# Copy the rest of the application code
COPY config.ru Gemfile Gemfile.lock Rakefile .ruby-version ./
COPY app app
COPY bin bin
COPY config config
COPY lib lib
COPY public public

ARG RAILS_RELATIVE_URL_ROOT
RUN echo "RAILS_RELATIVE_URL_ROOT set to: ${RAILS_RELATIVE_URL_ROOT}"

# Precompile assets
RUN RAILS_ENV=production \
  bundle exec rake assets:precompile \
  && mkdir -m 777 ${DIR}/coverage \
  && mkdir -m 777 ${DIR}/log

# Start a new build stage to minimise the final image size
FROM base

ARG image_name
ARG git_branch
ARG git_commit_hash
ARG github_run_number
ARG VERSION

LABEL com.epimorphics.name=$image_name \
      com.epimorphics.branch=$git_branch \
      com.epimorphics.build=$github_run_number \
      com.epimorphics.commit=$git_commit_hash \
      com.epimorphics.version=$VERSION

RUN addgroup -S app && adduser -S -G app app
EXPOSE 3000

WORKDIR ${DIR}

COPY --from=builder --chown=app /usr/local/bundle /usr/local/bundle
COPY --from=builder --chown=app ${DIR} .

USER app

# Add a script to be executed every time the container starts.
COPY entrypoint.sh "/app/entrypoint.sh"
ENTRYPOINT ["sh", "/app/entrypoint.sh"]
