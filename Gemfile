# frozen_string_literal: true

source 'https://rubygems.org'

gem 'execjs', '< 2.8.0'

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

gem 'jbuilder'
gem 'jquery-rails'

gem 'bootstrap-sass'
gem 'haml-rails'

group :doc do
  gem 'sdoc', require: false
end

gem 'byebug', group: %i[development test]

group :development do
  gem 'rb-readline'

  gem 'flamegraph'
  gem 'memory_profiler'
  gem 'rubocop'
  gem 'rubocop-rails'
  gem 'stackprof' # ruby 2.1+ only
end

# rubocop:disable Layout/LineLength
gem 'data_services_api', git: 'https://github.com/epimorphics/ds-api-ruby.git', branch: 'task/infrastructure-update'
# rubocop:enable Layout/LineLength
# gem 'data_services_api', path: '/home/ian/workspace/epimorphics/ds-api-ruby'
gem 'faraday'
gem 'faraday_middleware'
gem 'font-awesome-rails'
gem 'jquery-ui-rails'
gem 'sentry-raven'
gem 'yajl-ruby', require: 'yajl'

gem 'lr_common_styles', git: 'https://github.com/epimorphics/lr_common_styles.git'
# gem 'lr_common_styles', path: '/home/ian/projects/hmlr/lr_common_styles'
gem 'json_rails_logger', git: 'https://github.com/epimorphics/json-rails-logger.git', branch: 'main'

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
