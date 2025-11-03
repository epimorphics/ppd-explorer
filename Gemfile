# frozen_string_literal: true

source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails'

# Use Puma as the app server
gem 'puma'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'execjs'
# gem 'therubyracer', platforms: :ruby
gem 'libv8-node'

gem 'jbuilder'
gem 'jquery-rails'

gem 'bootstrap-sass'
gem 'haml-rails'

gem 'rubocop'
gem 'rubocop-rails'

gem 'faraday', '~> 2.13'
gem 'faraday-encoding', '>= 0.0.6'
gem 'faraday-follow_redirects', '>= 0.3.0'
gem 'faraday-retry', '>= 2.0'

gem 'font-awesome-rails'
gem 'get_process_mem'
gem 'jquery-ui-rails'
gem 'ostruct'
gem 'prometheus-client'
gem 'puma-metrics'
gem 'yajl-ruby', require: 'yajl'

# Sentry uses stackprof for performance profiling, has to be loaded before Sentry
gem 'stackprof'
gem 'sentry-rails' # rubocop:disable Bundler/OrderedGems

# Assets group is temporarily disabled due to versioning issues with Rails
# group :assets do
# Use SCSS for stylesheets
gem 'sass-rails'
# ! Webpacker removes the need for Uglifier so we can safely remove it.
# ! If you want to use Uglifier, uncomment the line below
# ! and ensure you have the 'uglifier' gem in your Gemfile.
# ! See https://www.mintbit.com/blog/rails-5-6-upgrade-es6-uglifier-bug/
# Use Uglifier as compressor for JavaScript assets
# gem 'uglifier', require: false
# end

group :doc do
  gem 'sdoc', require: false
end

gem 'byebug', groups: %i[development test]
gem 'dotenv', groups: %i[development test]

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
  gem 'htmlbeautifier'
  gem 'ruby-lsp'
  gem 'solargraph'
  # Devtools panel for Rails development - loading from the GitHub repo
  # (https://github.com/dejan/rails_panel/issues/209#issuecomment-2621877079_)
  gem 'meta_request', github: 'dejan/rails_panel', ref: 'meta_request-v0.8.5'

  gem 'rb-readline'

  gem 'flamegraph'
  gem 'memory_profiler'
end

# TODO: In production you want to set this to the gem from the epimorphics package repo
source 'https://rubygems.pkg.github.com/epimorphics' do
  gem 'data_services_api'
  gem 'json_rails_logger'
  gem 'lr_common_styles'
end

# TODO: While running the rails app locally for testing you can set gems to your local path
# ! These 'local' paths do not work with a docker image - use the repo instead
# gem 'data_services_api', path: '~/Epimorphics/shared/data_services_api'
# gem 'json_rails_logger', path: '~/Epimorphics/shared/json-rails-logger'
# gem 'lr_common_styles', path: '~/Epimorphics/clients/land-registry/projects/lr_common_styles'
