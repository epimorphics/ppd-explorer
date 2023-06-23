# frozen_string_literal: true

# Controller for user queries
class SearchController < ApplicationController
  attr_reader :preferences, :query_command

  def index
    create
  end

  # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
  def create
    @preferences = UserPreferences.new(params)

    if @preferences.empty?
      redirect_to controller: :ppd, action: :index
    else
      @query_command = QueryCommand.new(@preferences, use_compact_json?)
      @query_command.load_query_results

      if @query_command.success?
        render
      else
        render template: 'ppd/error'
      end
    end
  rescue StandardError => e
    e = e.cause || e
    status = case e
             when MalformedSearchError, ArgumentError
               :bad_request
             else
               e.status || :internal_server_error
             end

    render_error_page(e, e.message, status)
  end
  # rubocop:enable Metrics/MethodLength, Metrics/PerceivedComplexity

  def use_compact_json?
    !non_compact_formats.include?(request.format)
  end

  def non_compact_formats
    ['text/turtle']
  end

  private

  # rubocop:disable Layout/LineLength
  def render_error_page(err, message, status, template = 'ppd/error')
    uuid = SecureRandom.uuid

    Rails.logger.error "#{err.class.name} error #{uuid} ::: #{message} ::: #{err.class}"

    @error_message =
      ["<p class='error bg-warning'>#{message}.</p>",
       "<p>The log file reference for this error is<span class='sr-only'> Code</span>: <code>#{uuid}</code></p>",
       '<p>You can quote this reference to support staff so that they can investigate this specific incident.</p>'].join.html_safe
    render(template: template, status: status)
  end
  # rubocop:enable Layout/LineLength
end
