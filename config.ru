# frozen_string_literal: true

require_relative 'config/environment'
require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'

# use Rack::Deflator
use Prometheus::Middleware::Collector
use Prometheus::Middleware::Exporter

require ::File.expand_path('config/environment', __dir__)
run Rails.application
