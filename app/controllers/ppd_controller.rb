class PpdController < ApplicationController
  def index
  end

  def create
    start = Time.now
    @user_preferences = UserPreferences.new( params )
    @query_command = QueryCommand.new( @user_preferences )
    @query_command.load_query_results
    @time_taken = ((Time.now - start) * 1000).to_i
  end
end
