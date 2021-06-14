ARG RUBY_VERSION=2.6.6
ARG BUNDLER_VERSION=2.1.4

# Defining ruby version
FROM ruby:$RUBY_VERSION

# Set working dir and copy app
WORKDIR /usr/src/app
COPY . .

# Prerequisites for gems install
RUN apt-get install tzdata \
                    git

# Install bundler and gems
RUN gem install bundler:$BUNDLER_VERSION
RUN bundle install

# Set environment variables and expose the running port
ENV RAILS_ENV=$RAILS_ENV
EXPOSE 3000

# Precompile assets and add entrypoint script
RUN RAILS_ENV=production rake assets:precompile
ENTRYPOINT [ "sh", "./entrypoint.sh" ]
