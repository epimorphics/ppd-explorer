# frozen_string_literal: true

source 'https://rubygems.org'

ruby file: '.ruby-version'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 8.1'

# Use Puma as the app server
gem 'puma', '~> 7.2'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'
gem 'jquery-rails'

gem 'autoprefixer-rails'
gem 'dartsass-sprockets', '~> 3.2'

gem 'haml-rails'

# Faraday v2 requires individual middlewares to be specified
# Resolve open-ended gem versioning warnings by setting explicit version minimums
gem 'faraday', '~> 2.13', '>= 2.13.0'
gem 'faraday-encoding', '~> 0.0', '>= 0.0.6'
gem 'faraday-follow_redirects', '~> 0.3', '>= 0.3.0'
gem 'faraday-retry', '~> 2.0', '>= 2.0'

gem 'font-awesome-rails'
gem 'get_process_mem'
gem 'jquery-ui-rails'
gem 'ostruct'
gem 'prometheus-client'
gem 'puma-metrics'
gem 'yajl-ruby', require: 'yajl'

# Sentry uses stackprof for performance profiling, has to be loaded before Sentry
gem 'stackprof'
gem 'sentry-rails', '~> 6.0' # rubocop:disable Bundler/OrderedGems

group :doc do
  gem 'sdoc', require: false
end

gem 'byebug', groups: %i[development test]
gem 'dotenv', groups: %i[development test]

group :test do
  gem 'capybara'
  gem 'csv'
  gem 'json_expressions'
  gem 'minitest-rails', require: false
  gem 'minitest-reporters'
  gem 'minitest-spec-rails', require: false
  gem 'mocha'
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
  gem 'vcr'
  gem 'webmock'
end

group :development do
  gem 'rubocop', '~> 1.0', require: false
  gem 'rubocop-rails', '~> 2.0', require: false
  gem 'ruby-lsp'
  gem 'solargraph'
end

source 'https://rubygems.pkg.github.com/epimorphics' do
  gem 'data_services_api'
  gem 'json_rails_logger'
  gem 'lr_common_styles'
end
