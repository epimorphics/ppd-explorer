#!/bin/bash

# Set the environment
if [ -z "$RAILS_ENV" ]
then
  export RAILS_ENV=production
fi

# Run the rails app
exec ./bin/rails server
