ARG RUBY_VERSION=2.6.6

# Defining ruby version
FROM ruby:$RUBY_VERSION

# Prerequisites for gems install
RUN apt-get install tzdata \
                    git

# Set working dir and copy app
WORKDIR /usr/src/app
COPY Gemfile Rakefile ./
COPY app app
COPY bin bin
COPY config config
COPY lib lib
COPY public public
COPY vendor vendor
COPY entrypoint.sh .

RUN mkdir log

ARG BUNDLER_VERSION=2.1.4

# Install bundler and gems
RUN gem install bundler:$BUNDLER_VERSION
RUN bundle install

# Params
ARG RAILS_ENV="production"
ARG RAILS_SERVE_STATIC_FILES="true"
ARG RELATIVE_URL_ROOT="/app/ppd"
ARG API_SERVICE_URL

# Set environment variables and expose the running port
ENV RAILS_ENV=$RAILS_ENV
ENV RAILS_SERVE_STATIC_FILES=$RAILS_SERVE_STATIC_FILES
ENV RELATIVE_URL_ROOT=$RELATIVE_URL_ROOT
ENV SCRIPT_NAME=$RELATIVE_URL_ROOT
ENV API_SERVICE_URL=$API_SERVICE_URL
EXPOSE 3000

# Precompile assets and add entrypoint script
RUN rake assets:precompile
ENTRYPOINT [ "sh", "./entrypoint.sh" ]
