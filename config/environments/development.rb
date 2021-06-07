# frozen_string_literal: true

PpdExplorer::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Don't print a log message every time an asset file is loaded
  config.assets.quiet = true

  config.log_tags = %i[subdomain request_id request_method]
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  config.api_service_url = ENV['API_SERVICE_URL'] || 'https://lr-ppd-dev-pres.epimorphics.net'

  config.accessibility_document_path = '/doc/accessibility'

  config.contact_email_address = 'data.services@mail.landregistry.gov.uk'
end
