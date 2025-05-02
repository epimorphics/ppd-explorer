# frozen_string_literal: true

require 'version'

Rails.application.reloader.to_prepare do
  if ENV['SENTRY_API_KEY']
    SENTRY_ENVIRONMENT = ENV.fetch('SENTRY_ENVIRONMENT', Rails.env)
    SENTRY_PROJECT = ENV.fetch('SENTRY_PROJECT', 'lr-dgu-ppd')

    Sentry.init do |config|
      # https://docs.sentry.io/platforms/ruby/configuration/options/#breadcrumbs-logger
      config.breadcrumbs_logger = %i[sentry_logger monotonic_active_support_logger http_logger]
      # * Set Sentry SDK errors to be logged with backtrace
      config.debug = SENTRY_ENVIRONMENT.include?('dev')
      # * The DSN tells the SDK where to send events.
      config.dsn = ENV['SENTRY_API_KEY']
      # ! Only report errors in these environments:
      config.enabled_environments = %w[production prod preprod dev]
      # ! Ignore exceptions that are not useful to us
      config.excluded_exceptions += [
        'ActionController::BadRequest',
        'ActionController::RoutingError',
        'ActiveRecord::RecordNotFound'
      ]
      # * Set the environment name from the SENTRY_ENVIRONMENT instance configuration value
      config.environment = SENTRY_ENVIRONMENT
      # ^ Default to only reporting info, warnings and errors to Sentry
      config.logger.level = Rails.application.config.log_level || :info
      # * Set the release version to the current version
      config.release = "#{SENTRY_PROJECT}@#{Version::VERSION}"
      # * Set traces_sample_rate to 1.0 to capture 100% of transactions for tracing.
      # ! Sentry recommends adjusting this value in production hence the ternary operator.
      config.traces_sample_rate = Rails.env.development? ? 1.0 : 0.1
      # * Set profiles_sample_rate to profile 100% of sampled transactions.
      # ! Sentry recommends adjusting this value in production hence the ternary operator.
      config.profiles_sample_rate = Rails.env.production? ? 1.0 : 0.1
    end

    # * Set additional tags for the Sentry event to allow for better filtering in the Sentry UI
    # ? These tags are set in either a local .env file or the instance configuration
    # ! `.compact!` removes any nil values from the sentry_tags hash before setting the tags
    sentry_tags = {
      'band' => ENV.fetch('SENTRY_BAND', nil),
      'enabled' => ENV.fetch('SENTRY_ENABLED', nil),
      'hostname' => ENV.fetch('SENTRY_HOSTNAME', nil)
    }.compact!
    # * Set the tags in the Sentry event with remaining values but only if there are any
    sentry_tags&.each { |k, v| Sentry.set_tags(k.to_s => v) }
  end
end
