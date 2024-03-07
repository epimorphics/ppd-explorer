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
               :internal_server_error
             end

    render_error_page(e, e.message, status)
  end
  # rubocop:enable Metrics/MethodLength, Metrics/PerceivedComplexity

  def use_compact_json?
    non_compact_formats.exclude?(request.format)
  end

  def non_compact_formats
    ['text/turtle']
  end

  private

  # rubocop:disable Layout/LineLength, Metrics/MethodLength
  def render_error_page(err, message, status, template = 'ppd/error')
    # link the error to the actual request id otherwise generate one for this error
    uuid = Thread.current[:request_id] || SecureRandom.uuid

    @message = message

    # log the error with as much detail as possible in development to aid in resolving the issue
    message = "#{err.class.name} error #{uuid} ::: #{message} ::: #{err.class}" if Rails.env.development?

    # Keep it simple silly in production!
    Rails.logger.error message

    @error_message =
      [
        '<p>Include the following information to support staff so that they can investigate this specific incident.</p>',
        "<p class='error bg-warning'>#{@message}.</p>",
        "<p>The trace reference for this error is<span class='sr-only px-1'> Code</span>: <code>#{uuid}</code></p>"
      ].join.html_safe
    render(template: template, status: status)
  end
  # rubocop:enable Layout/LineLength, Metrics/MethodLength
end
