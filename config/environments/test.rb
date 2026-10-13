# frozen_string_literal: true

PpdExplorer::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = false

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure static file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = { 'Cache-Control' => 'public, max-age=3600' }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  # The boolean form was removed in Rails 8.0: `false` is not rejected, it is
  # silently treated as `:all`, so exceptions were rendered rather than raised.
  config.action_dispatch.show_exceptions = :none

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Set the log level to the value of the LOG_LEVEL environment variable, or 'info' if not set
  config.log_level = ENV.fetch('LOG_LEVEL', 'info').to_sym

  # When sync mode is true, all output is immediately flushed to the underlying
  # operating system and is not buffered by Ruby internally.
  $stdout.sync = true

  # Keep test logs in log/test.log so request log entries don't flood the test
  # output. The epilog_rails Railtie assigns config.logger unconditionally,
  # overwriting any logger set here, so redirect its output once booted instead.
  config.after_initialize do
    file_logger = ActiveSupport::Logger.new(Rails.root.join('log/test.log'), level: Rails.logger.level)
    file_logger.formatter = EpilogRails::JsonFormatter.new
    Rails.logger.broadcasts.dup.each { |sink| Rails.logger.stop_broadcasting_to(sink) }
    Rails.logger.broadcast_to(file_logger)
    # dotenv took its own copy of the logger while it still wrote to stdout, and
    # logs a line before every test
    Dotenv::Rails.instance.logger = Rails.logger
  end

  # API location can be specified in the environment
  # But defaults to the dev service
  config.api_service_url = ENV.fetch('API_SERVICE_URL', 'http://localhost:8888')
end
