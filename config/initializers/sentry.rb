# frozen-string-literal: true

Raven.configure do |config|
  config.dsn = config.dsn = 'https://06e1842bac0b49fcae94e8a33ef30910@sentry.io/1859747'
  config.current_environment = ENV['DEPLOYMENT_ENVIRONMENT'] || Rails.env
  config.environments = %w[production test]
  config.release = Version::VERSION
  config.tags = { app: 'lr-dgu-ppd' }
  config.excluded_exceptions += ['ActionController::BadRequest']
end
