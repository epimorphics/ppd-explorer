# frozen_string_literal: true

source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '< 6.0.0'

# Use Puma as the app server
gem 'puma'

# Use SCSS for stylesheets
gem 'sass-rails'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
# gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'

gem 'bootstrap-sass'
gem 'haml-rails'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

gem 'byebug', group: %i[development test]

group :development do
  gem 'rb-readline'
  # gem 'quiet_assets'

  gem 'flamegraph'
  gem 'memory_profiler'
  gem 'stackprof' # ruby 2.1+ only
  gem 'rubocop'
  gem 'rubocop-rails'
end

gem 'data_services_api', git: 'https://github.com/epimorphics/ds-api-ruby.git'
# gem 'data_services_api', path: '/home/ian/workspace/epimorphics/ds-api-ruby'
gem 'faraday'
gem 'faraday_middleware'
gem 'font-awesome-rails'
gem 'jquery-ui-rails'
gem 'sentry-raven'
gem 'yajl-ruby', require: 'yajl'

gem 'lr_common_styles', git: 'https://github.com/epimorphics/lr_common_styles.git'
# gem 'lr_common_styles', path: '/home/ian/projects/hmlr/lr_common_styles'

group :test do
  gem 'capybara'
  gem 'capybara-selenium'
  gem 'capybara_minitest_spec'
  # gem 'chromedriver-helper'
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
