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
        Rails.logger.debug "Using compact JSON = #{use_compact_json?}"
        @query_command = QueryCommand.new( @preferences, use_compact_json? )
        @query_command.load_query_results
        @time_taken = ((Time.now - start) * 1000).to_i

        render template: "ppd/error" unless @query_command.success?
      end
    rescue => e
      uuid = SecureRandom.uuid

      Rails.logger.error "Top-level error trap in search_controller #{uuid}"
      Rails.logger.error "Query error #{uuid} ::: #{e.message}"
      Rails.logger.error "Query error #{uuid} ::: #{e.backtrace.join("\n")}"

      @error_message = "The log file reference for this error is: #{uuid}."
      render template: "ppd/error"

    end
  end

  def use_compact_json?
    ! non_compact_formats.include?( request.format )
  end

  def non_compact_formats
    ["text/turtle"]
  end
end
