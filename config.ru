# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.
require 'dotenv'
# Load environment variables using Dotenv. If a .env file exists, it will
# set environment variables from that file (useful for dev environments)
Dotenv.load

if Rails.env.development? && Rails.debug?
  puts 'Loading environment variables from .env file'
  h = {}
  ENV.each_pair { |name, value| h[name] = value }
  h.each do |name, value|
    puts "#{name}: #{value}\n" if name == 'API_SERVICE_URL'
  end
end

require_relative 'config/environment'

unless Rails.env.test?
  require 'prometheus/middleware/collector'
  require 'prometheus/middleware/exporter'

  use Prometheus::Middleware::Collector
  use Prometheus::Middleware::Exporter
end

require File.expand_path('config/environment', __dir__)

map Rails.application.config.relative_url_root || '/' do
  run Rails.application
end
