source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.6'


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

gem 'haml-rails'
gem 'bootstrap-sass'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# gem 'debugger', group: [:development, :test]
group :development do
  gem 'rb-readline'
  gem 'pry'
  gem 'pry-stack_explorer'
  gem 'quiet_assets'
end


gem 'govuk_frontend_toolkit', github: "alphagov/govuk_frontend_toolkit_gem", :submodules => true
gem 'data_services_api', git: "git@github.com:epimorphics/ds-api-ruby.git"
gem 'yajl-ruby', require: 'yajl'
gem 'font-awesome-rails'
gem 'faraday', '~> 0.9.2'
gem "faraday_middleware", "~> 0.10.0"
gem 'jquery-ui-rails'

group :test do
  gem 'minitest', '~> 5.5 '
  gem 'minitest-rg', '~> 5.1'
  gem 'capybara-webkit', '~> 1.1'
  gem 'minitest-capybara', '~> 0.4'
  gem 'minitest-spec-rails', '~> 5.2'
  gem 'json_expressions', "~> 0.8"
  gem 'vcr'
  gem 'minitest-vcr'
  gem 'webmock'
end
