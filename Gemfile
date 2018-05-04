# frozen_string_literal: true

source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '5.0.2'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0.4'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
# gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.3'

gem 'bootstrap-sass'
gem 'haml-rails'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# gem 'debugger', group: [:development, :test]
group :development do
  gem 'byebug'
  gem 'rb-readline'
  # gem 'quiet_assets'

  gem 'flamegraph'
  gem 'memory_profiler'
  gem 'rack-mini-profiler'
  gem 'stackprof' # ruby 2.1+ only
end

# gem 'data_services_api', git: 'git@github.com:epimorphics/ds-api-ruby.git'
gem 'data_services_api', git: 'git@github.com:epimorphics/ds-api-ruby.git'
# gem 'data_services_api', path: '/home/ian/workspace/epimorphics/ds-api-ruby'
gem 'faraday', '~> 0.11.0'
gem 'faraday_middleware', '~> 0.11.0.1'
gem 'font-awesome-rails'
gem 'jquery-ui-rails'
gem 'lr_common_styles', github: 'epimorphics/lr_common_styles'
gem 'yajl-ruby', require: 'yajl'
# gem 'lr_common_styles', path: '/home/ian/workspace/land-registry/lr_common_styles'

group :test do
  gem 'capybara_minitest_spec'
  gem 'json_expressions', '~> 0.8'
  gem 'minitest-rails-capybara'
  gem 'minitest-reporters'
  gem 'minitest-spec-rails'
  gem 'minitest-vcr'
  gem 'mocha'
  gem 'simplecov', require: false
  gem 'vcr'
  gem 'webmock'
end
