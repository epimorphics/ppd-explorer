# frozen_string_literal: true

# Controller for user queries
class SearchController < ApplicationController
  def index
    create
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  # rubocop:disable Metrics/PerceivedComplexity
  def create
    @preferences = UserPreferences.new(params)

    if @preferences.empty?
      redirect_to controller: :ppd, action: :index
    else
      start = Time.now

      @query_command = QueryCommand.new(@preferences, use_compact_json?)
      @query_command.load_query_results
      after_query = Time.now
      @time_taken = ((after_query - start) * 1000).to_i
      Rails.logger.debug "Time taken for query phase: #{@time_taken}ms"

      if @query_command.success?
        render
      else
        render template: 'ppd/error'
      end
    end
  rescue StandardError => err
    e = err.cause || err
    status = case e
             when MalformedSearchError, ArgumentError
               400
             else
               500
             end

    render_error(e, e.message, status)
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  # rubocop:enable Metrics/PerceivedComplexity

  def use_compact_json?
    !non_compact_formats.include?(request.format)
  end

  def non_compact_formats
    ['text/turtle']
  end

  private

  def render_error(err, message, status, template = 'ppd/error')
    uuid = SecureRandom.uuid

    Rails.logger.error "#{err.class.name} error #{uuid} ::: #{message} ::: #{err.class}"

    @error_message =
      ["<span class='error bg-warning'>#{message}.</span>",
       "The log file reference for this error is: #{uuid}."].join('<br />').html_safe
    render(template: template, status: status)
  end
end
