# Params
ARG RAILS_ENV="production"

# Defining ruby version
FROM ruby:2.6.6

# Set working dir and copy app
WORKDIR /usr/src/app
COPY . .

# Prerequisites for gems install
RUN apt-get install tzdata \
                    git

# Install bundler and gems
RUN gem install bundler
RUN bundle install

# Set environment variables and expose the running port
ENV RAILS_ENV=$RAILS_ENV
EXPOSE 3000

# Precompile assets and add entrypoint script
RUN RAILS_ENV=production rake assets:precompile
ENTRYPOINT [ "sh", "./entrypoint.sh" ]
