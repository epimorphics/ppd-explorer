# frozen_string_literal: true

# Controller for PPD search form
class PpdController < ApplicationController
  def index
    LoggingHelper.log_request({ params: params, path: request.path }, 'info')
    @preferences = UserPreferences.new(params)
  end
end
