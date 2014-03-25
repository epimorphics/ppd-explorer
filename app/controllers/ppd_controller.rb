class PpdController < ApplicationController
  def index
  end

  def create
    @user_preferences = UserPreferences.new( params )
    @query_command = QueryCommand.new( @user_preferences )
    @query_command.load_query_results
  end
end
