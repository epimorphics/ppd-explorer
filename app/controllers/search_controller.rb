# frozen_string_literal: true

# Controller for user queries
class SearchController < ApplicationController
  attr_reader :preferences, :query_command

  def index
    create
  end

  def create
    @preferences = UserPreferences.new(params)

    if @preferences.empty?
      redirect_to controller: :ppd, action: :index
    else
      @query_command = QueryCommand.new(@preferences, use_compact_json?)
      @query_command.load_query_results
    end
  end

  def use_compact_json?
    non_compact_formats.exclude?(request.format)
  end

  def non_compact_formats
    ['text/turtle']
  end
end
