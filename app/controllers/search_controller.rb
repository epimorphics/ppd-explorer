# frozen_string_literal: true

# Controller for user queries
class SearchController < ApplicationController
  attr_reader :preferences, :query_command

  def index
    create
  end

  def create # rubocop:disable Metrics/MethodLength
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
    rescue_standard_error(e)
  end

  # Determine status symbol to pass to the error page
  def rescue_standard_error(err)
    status = case err
             when MalformedSearchError, ArgumentError
               :bad_request
             else
               :internal_server_error
             end
    # Display the actual rails error stack trace while in development
    render_error_page(err, err.message, status) unless Rails.env.development?
    # To check the error page in development, set the RAILS_ENV to production or test
  end

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
    @message = "#{Rack::Utils::SYMBOL_TO_STATUS_CODE[status]} ~ #{err.class.name} error: #{message}" if Rails.env.development?

    # Keep it simple silly in production!
    log_error(Rack::Utils::SYMBOL_TO_STATUS_CODE[status], message)

    @error_message =
      [
        '<p>Include the following information to support staff so that they can investigate this specific incident.</p>',
        "<p class='error bg-warning'>#{@message}.</p>",
        "<p>The trace reference for this error is<span class='sr-only px-1'> Code</span>: <code>#{uuid}</code></p>"
      ].join.html_safe # rubocop:disable Rails/OutputSafety
    render(template: template, status: status)
  end
  # rubocop:enable Layout/LineLength, Metrics/MethodLength

  # Log the error with the appropriate log level based on the status code
  def log_error(status, message)
    case status
    when 500..599
      Rails.logger.error(message)
    when 400..499
      Rails.logger.warn(message)
    else
      Rails.logger.info(message)
    end
  end

end
