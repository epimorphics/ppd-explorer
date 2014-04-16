class PpdDataController < ApplicationController
  include DsapiTurtleFormatter

  def show
    @preferences = UserPreferences.new( params )

    if is_explanation?
      # explanation = ExplainCommand.new( preferences).load_explanation
      # redirect_to qonsole_rails.root_path( query: explanation[:sparql] )
    elsif is_data_request?
      @query_command = QueryCommand.new( @preferences )
      @query_command.load_query_results( limit: :all, download: true )
    end
  end

  def is_explanation?
    params[:explain]
  end

  def is_data_request?
    request.format == Mime::Type.lookup_by_extension( :ttl ) ||
    request.format == Mime::Type.lookup_by_extension( :csv )
  end

end
