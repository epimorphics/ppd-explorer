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
    rescue MalformedSearchError => e
      uuid = SecureRandom.uuid

      Rails.logger.error "Top-level error trap in search_controller #{uuid}"
      Rails.logger.error "Malformed search error #{uuid} ::: #{e.message}"

      @error_message = "<span class='error bg-warning'>#{e.message}.</span><br />The log file reference for this error is: #{uuid}.".html_safe
      render template: "ppd/error", status: 400

    rescue => e
      uuid = SecureRandom.uuid

      Rails.logger.error "Top-level error trap in search_controller #{uuid}"
      Rails.logger.error "Query error #{uuid} ::: #{e.message} ::: #{e.class}"
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
