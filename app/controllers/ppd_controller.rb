# frozen_string_literal: true

# Controller for PPD search form
class PpdController < ApplicationController
  def index
    @preferences = UserPreferences.new(params)
  end
end
