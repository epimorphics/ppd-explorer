# Params
ARG RAILS_ENV="production"

# Defining ruby version
FROM ruby:2.6.6

# Copy app and set working dir
COPY . /application
WORKDIR /application

# Prerequisites for gems install
RUN rm -rf /application/Gemfile.lock
RUN apt-get install tzdata \
                    git

# Install bundler and gems
RUN gem install bundler:2.1.4
RUN bundle install --without="development"

# Set environment variables and expose the running port
ENV RAILS_ENV=$RAILS_ENV
EXPOSE 3000

# Add app entrypoint script
ENTRYPOINT [ "sh", "./entrypoint.sh" ]