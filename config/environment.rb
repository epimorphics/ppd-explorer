# frozen_string_literal: true

# Load the Rails application.
require File.expand_path('application', __dir__)

# Initialize the Rails application.
PpdExplorer::Application.initialize!

# Custom logger
logger = ActiveSupport::Logger.new("log/#{Rails.env}.log")
logger.formatter = proc do |severity, time, prog_name, msg|
  msg_one_line = msg.gsub(/\n/, '\n')
  "#{msg_one_line} name=#{prog_name} severity=#{severity} time=#{time.iso8601}\n"
end
Rails.logger = ActiveSupport::TaggedLogging.new(logger)
