# frozen_string_literal: true

# Load the Rails application.
require File.expand_path('application', __dir__)

# Initialize the Rails application.
PpdExplorer::Application.initialize!

# Custom logger
logger = ActiveSupport::Logger.new("log/#{Rails.env}.log")
logger.formatter = proc do |severity, time, prog_name, msg|
  msg_without_time = msg.gsub(/ at [0-9 :+\-]*/, '')
  msg_one_line = msg_without_time.gsub(/\n/, '\n')
  "#{severity} #{time.iso8601(3)} #{msg_one_line}\n"
end
Rails.logger = ActiveSupport::TaggedLogging.new(logger)
