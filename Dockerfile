ARG RUBY_VERSION=2.6.6

# Defining ruby version
FROM ruby:$RUBY_VERSION

# Prerequisites for gems install
RUN apt-get install tzdata \
                    git

# Set working dir and copy app
WORKDIR /usr/src/app
COPY Gemfile Rakefile config.ru entrypoint.sh ./
COPY app app
COPY bin bin
COPY config config
COPY lib lib
COPY public public
COPY vendor vendor

RUN mkdir log

ARG BUNDLER_VERSION=2.1.4

# Install bundler and gems
RUN gem install bundler:$BUNDLER_VERSION
RUN bundle install

# Set environment variables and expose the running port
ENV RAILS_ENV="production"
ENV RAILS_SERVE_STATIC_FILES="true"
ENV RAILS_RELATIVE_URL_ROOT="/app/ppd"
ENV SCRIPT_NAME="/app/ppd"
ENV API_SERVICE_URL="http://localhost:8080"
EXPOSE 3000

# Precompile assets and add entrypoint script
RUN rake assets:precompile
ENTRYPOINT [ "sh", "./entrypoint.sh" ]
