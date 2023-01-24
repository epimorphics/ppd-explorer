# frozen_string_literal: true

require 'syslog/logger'

PpdExplorer::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both thread web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy
  # config.action_dispatch.rack_cache = true

  # Disable Rails's static asset server (Apache or nginx will already do this).
  # config.serve_static_assets = false
  config.serve_static_files = ENV['RAILS_SERVE_STATIC_FILES'] || true

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Generate digests for assets URLs.
  config.assets.digest = true

  # Version of your assets, change this if you want to expire all your assets.
  config.assets.version = '1.0'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Set to :debug to see everything in the log.
  config.log_level = :info

  # Prepend all log lines with the following tags.
  config.log_tags = %i[subdomain request_id]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new)
  $stdout.sync = true
  config.logger = JsonRailsLogger::Logger.new($stdout)

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # * Set cache control headers for HMLR apps to be public and cacheable
  # * Price Paid Data uses a time limit of 5 minutes (300 seconds)
  # This will affect assets served from /app/assets
  config.static_cache_control = "public, max-age=#{5.minutes.to_i}"

  # This will affect assets in /public, e.g. webpacker assets.
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{5.minutes.to_i}",
    'Expires' => 5.minutes.from_now.to_formatted_s(:rfc822)
  }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
  # config.assets.precompile += %w( search.js )

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Disable automatic flushing of the log to improve performance.
  # config.autoflush_log = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  # config.log_formatter = ::Logger::Formatter.new

  # Specify that we're not at the root
  config.relative_url_root = ENV['RAILS_RELATIVE_URL_ROOT'] || '/'

  # API location can be specified in the environment
  # But defaults to the dev service
  config.api_service_url = ENV['API_SERVICE_URL'] || 'http://localhost:8080'

  config.accessibility_document_path = '/accessibility'
  config.privacy_document_path = '/privacy'

  config.contact_email_address = 'data.services@mail.landregistry.gov.uk'
end
