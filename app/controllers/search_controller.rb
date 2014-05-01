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
        @query_command = QueryCommand.new( @preferences )
        @query_command.load_query_results
        @time_taken = ((Time.now - start) * 1000).to_i

        Rails.logger.info "Query command success = '#{@query_command.success?}'"
        # render template: "ppd/error" unless @query_command.success?
        render plain: "Query timeout"
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
end
