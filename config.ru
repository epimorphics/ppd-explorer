# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

unless Rails.env.test?
  require 'prometheus/middleware/collector'
  require 'prometheus/middleware/exporter'

  use Prometheus::Middleware::Collector
  use Prometheus::Middleware::Exporter
end

require ::File.expand_path('config/environment', __dir__)

map Rails.application.config.relative_url_root || '/' do
  run Rails.application
end
