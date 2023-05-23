# frozen_string_literal: true

require File.expand_path('boot', __dir__)

# Pick the frameworks you want:
# require "active_record/railtie"
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'sprockets/railtie'
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module PpdExplorer
  # :nodoc:
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.assets.paths << Rails.root.join('app', 'assets', 'fonts')
  end
end

# Monkey-patch the bit of Rails that emits the start-up log message, so that it
# is written out in JSON format that our combined logging service can handle
# This version is Rails 5.x specific. A different pattern is needed for Rails 6
# applications.
module Rails
  # :nodoc:
  class Server
    # :nodoc:
    def print_boot_information
      url = "on #{options[:SSLEnable] ? 'https' : 'http'}://#{options[:Host]}:#{options[:Port]}"

      msg = {
        ts: DateTime.now.utc.strftime('%FT%T.%3NZ'),
        level: 'INFO',
        message: "Starting #{server} Rails #{Rails.version} in #{Rails.env} #{url}"
      }
      puts msg.to_json
    end
  end
end
