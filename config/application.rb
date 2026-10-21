# frozen_string_literal: true

require File.expand_path('boot', __dir__)

# Pick the frameworks you want:
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
    # Initialise configuration defaults for the given Rails version.
    config.load_defaults 8.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Use default paths for documentation.
    config.accessibility_document_path = '/accessibility'
    config.privacy_document_path = '/privacy'

    # Default contact email address to Land Registry Data Services
    config.contact_email_address = 'data.services@mail.landregistry.gov.uk'

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Quiet SASS deprecation warnings coming from dependencies
    config.sass.quiet_deps = true
    # Silence @import deprecation warnings during migration to @use/@forward
    # See: https://sass-lang.com/d/import
    config.sass.silence_deprecations = ['import']
    # Add fonts path to asset pipeline
    config.assets.paths << Rails.root.join('app/assets/fonts')

    # Render error pages through the application, rather than static files in
    # public/, so they use the application layout.
    #
    # ActionDispatch::ShowExceptions catches the exception, maps it to a status via
    # `rescue_responses` below, resets the response, and hands the request to
    # ErrorsController with the path rewritten to the status code. It runs outside
    # the router, so unlike `rescue_from` it also catches routing errors. The
    # application never decides which status an exception deserves.
    #
    # Dispatched straight to the controller rather than via `routes`, so the error
    # pages have no public URLs: requesting /500 directly is just an unmatched path.
    # The lambda defers the constant lookup until an error occurs, after autoloading
    # is set up. `render_error` also copes with requests whose params can't be parsed.
    config.exceptions_app = ->(env) { ErrorsController.render_error(env) }

    # Statuses for the errors the application expects. Rails already knows the
    # framework's own exceptions (RoutingError is 404, ParameterMissing is 400,
    # and so on), so only these need registering.
    #
    # The rest are failures of the Data Services API, given a status by who has
    # to act. It could not be reached, did not answer in time, or is failing
    # (5xx): 503, 504 and 503, raised by the data_services_api gem or ApiError
    # and left to propagate. Any other error response, such as a 404 from an
    # endpoint that should exist, is an upstream or deployment fault: 502. These
    # are counted by the api_* metrics, not as internal application errors.
    #
    # An ApiQueryRejectedError (the API rejected the query we built) is not
    # registered: it is a bug in this application, so it stays a 500.
    config.action_dispatch.rescue_responses.merge!(
      'MalformedSearchError' => :bad_request,
      'Faraday::ConnectionFailed' => :service_unavailable,
      'Faraday::TimeoutError' => :gateway_timeout,
      'ApiUnavailableError' => :service_unavailable,
      'ApiBadResponseError' => :bad_gateway
    )

    # Expected failures (404, 400, 422, ...) are already recorded by the
    # request's completed log entry, so don't also log them as exceptions.
    config.action_dispatch.log_rescued_responses = false
  end
end

# Monkey-patch the bit of Rails that emits the start-up log message, so
# that it is written out in JSON format that our combined logging
# service can handle. `epilog_rails` formats Rails.logger and Puma output, but
# this banner is printed directly by the server command.
module Rails # rubocop:disable Style/OneClassPerFile
  # :nodoc:
  module Command
    # :nodoc:
    class ServerCommand
      def print_boot_information(server, url)
        msg = "Starting #{server} Rails #{Rails.version} in #{Rails.env}"
        msg += " on #{url}" if url
        info = {
          ts: DateTime.now.utc.strftime('%FT%T.%3NZ'),
          level: 'INFO',
          message: msg
        }
        say info.to_json
      end
    end
  end
end
