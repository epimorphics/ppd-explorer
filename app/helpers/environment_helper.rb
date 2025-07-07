# frozen_string_literal: true

# :nodoc:
module EnvironmentHelper
  module_function

  # This module provides helper methods related to the current environment.
  # It can be used to display the current environment in the UI, such as in page headers.

  # Returns the current environment, defaulting to 'development' if not set.
  def environment
    # changing this to default to development for now
    ENV.fetch('SENTRY_ENVIRONMENT', 'development')
  end

  def environment_title
    return if environment.match?(/prod/i)

    "[#{environment}] "
  end

  def environment_label
    return if environment.match?(/prod/i)

    content_tag(:span, class: 'c-page-header__environment') do
      "(#{environment})"
    end
  end
end
