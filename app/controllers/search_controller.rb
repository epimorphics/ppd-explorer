class SearchController < ApplicationController
  def index
    create
  end

  def create
    @preferences = UserPreferences.new( params )

    if @preferences.empty?
      redirect_to controller: :ppd, action: :index
    else
      start = Time.now
      @query_command = QueryCommand.new( @preferences )
      @query_command.load_query_results
      @time_taken = ((Time.now - start) * 1000).to_i
    end
  end
end
