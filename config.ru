# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

# ! DO NOT TRY TO LOAD ENV FILES IN PRODUCTION ENVIRONMENT !
unless Rails.env.production?
  require 'dotenv'
  # Load environment variables using Dotenv. If a .env file exists, it will
  # set environment variables from that file (useful for dev environments)
  Dotenv.load

  # Convert ENV to a hash for logging purposes
  h = {}
  ENV.each_pair { |name, value| h[name] = value }
  # Log the requested environment variable(s) to the console
  h.each do |name, value|
    msg = {
      ts: DateTime.now.utc.strftime('%FT%T.%3NZ'),
      level: 'INFO',
      message: "Loaded '#{value}' as '#{name}' environment variable"
    }
    puts msg.to_json if name.match(/API_SERVICE_URL/)
  end
end

require_relative 'config/environment'

unless Rails.env.test?
  require 'prometheus/middleware/collector'
  require 'prometheus/middleware/exporter'

  use Prometheus::Middleware::Collector
  use Prometheus::Middleware::Exporter
end

map Rails.application.config.relative_url_root || '/' do
  run Rails.application
end
