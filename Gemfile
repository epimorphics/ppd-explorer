# frozen_string_literal: true

source 'https://rubygems.org'

gem 'execjs'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails'

# Use Puma as the app server
gem 'puma'

# Use SCSS for stylesheets
gem 'sass-rails'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby
gem 'libv8-node'

gem 'jbuilder'
gem 'jquery-rails'

gem 'bootstrap-sass'
gem 'haml-rails'

gem 'rubocop'
gem 'rubocop-rails'

group :doc do
  gem 'sdoc', require: false
end

gem 'byebug', group: %i[development test]

group :test do
  gem 'capybara'
  gem 'capybara_minitest_spec'
  gem 'capybara-selenium'
  gem 'json_expressions'
  gem 'minitest-rails'
  gem 'minitest-reporters'
  gem 'minitest-spec-rails'
  gem 'minitest-vcr'
  gem 'mocha'
  gem 'simplecov', require: false
  gem 'vcr'
  gem 'webdrivers'
  gem 'webmock'
end

group :development do
  gem 'rb-readline'

  gem 'flamegraph'
  gem 'memory_profiler'

  gem 'stackprof' # ruby 2.1+ only
end

gem 'faraday'
gem 'faraday_middleware'
gem 'font-awesome-rails'
gem 'get_process_mem'
gem 'jquery-ui-rails'
gem 'prometheus-client'
gem 'sentry-rails'
gem 'yajl-ruby', require: 'yajl'

gem 'puma-metrics'

# TODO: In production you want to set this to the gem from the epimorphics package repo
source 'https://rubygems.pkg.github.com/epimorphics' do
  gem 'data_services_api'
  gem 'json_rails_logger'
  gem 'lr_common_styles'
end

# rubocop:disable Layout/LineLength
# TODO: While running the rails app locally for testing you can set gems to your local path
# ! These "local" paths do not work with a docker image - use the repo instead
# gem 'data_services_api', path: '~/Epimorphics/shared/data_services_api'
# gem 'json_rails_logger', path: '~/Epimorphics/shared/json-rails-logger'
# gem 'lr_common_styles', path: '~/Epimorphics/clients/land-registry/projects/lr_common_styles'
# rubocop:enable Layout/LineLength
