#!/bin/bash
set -e

# Remove any pre-existing server.pid for Rails.
rm -f ./tmp/pids/server.pid
mkdir -pm 1777 ./tmp

# Set the environment
[ -z "$RAILS_ENV" ] && RAILS_ENV=production

# Check for API Service URL variable and log it
[ -n "$API_SERVICE_URL" ] && echo "{\"ts\":\"$(date -u +%FT%T.%3NZ)\",\"level\":\"INFO\",\"message\":\"API_SERVICE_URL=${API_SERVICE_URL}\"}"

# Check for RAILS_RELATIVE_URL_ROOT variable and log it
[ -n "$RAILS_RELATIVE_URL_ROOT" ] && echo "{\"ts\":\"$(date -u +%FT%T.%3NZ)\",\"level\":\"INFO\",\"message\":\"RAILS_RELATIVE_URL_ROOT=${RAILS_RELATIVE_URL_ROOT}\"}"

# Handle secrets based on env
[ "$RAILS_ENV" == "production" ] && [ -z "$SECRET_KEY_BASE" ] && SECRET_KEY_BASE=$(./bin/rails secret) && export SECRET_KEY_BASE

# Log the rails command that will be executed
echo "{\"ts\":\"$(date -u +%FT%T.%3NZ)\",\"level\":\"INFO\",\"message\":\"exec ./bin/rails server -e ${RAILS_ENV} -b 0.0.0.0\"}"

# Execute the rails command
exec ./bin/rails server -e "${RAILS_ENV}" -b 0.0.0.0
