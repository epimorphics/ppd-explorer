class SearchController < ApplicationController
  def index
    create
  end

  def create
    begin
      @preferences = UserPreferences.new( params )

      if @preferences.empty?
        redirect_to controller: :ppd, action: :index
      else
        start = Time.now

        @query_command = QueryCommand.new( @preferences, use_compact_json? )
        @query_command.load_query_results
        @time_taken = ((Time.now - start) * 1000).to_i

        render template: "ppd/error" unless @query_command.success?
      end
    rescue => err
      e = err.cause || err
      status = case e
        when MalformedSearchError, ArgumentError
          400
        else
          500
        end

      render_error( e, e.message, status )
    end
  end

  def use_compact_json?
    ! non_compact_formats.include?( request.format )
  end

  def non_compact_formats
    ["text/turtle"]
  end

  :private

  def render_error( e, message, status, template = "ppd/error" )
    uuid = SecureRandom.uuid

    Rails.logger.error "#{e.class.name} error #{uuid} ::: #{message} ::: #{e.class}"
    Rails.logger.error "Query error #{uuid} ::: #{e.backtrace.join("\n")}" if Rails.application.config.consider_all_requests_local

    @error_message = "<span class='error bg-warning'>#{message}.</span><br />The log file reference for this error is: #{uuid}.".html_safe
    render( template: template, status: status )

  end
end
