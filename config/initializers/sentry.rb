# frozen-string-literal: true

if ENV['SENTRY_API_KEY']
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_API_KEY']
    config.environment = ENV['DEPLOYMENT_ENVIRONMENT'] || Rails.env
    config.enabled_environments = %w[production]
    config.release = Version::VERSION
    config.breadcrumbs_logger = %i[active_support_logger http_logger]
    config.excluded_exceptions += ['ActionController::BadRequest']
  end
end
