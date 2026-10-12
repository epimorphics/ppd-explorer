# frozen_string_literal: true

# :nodoc:
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

  # Temporarily disable csrf for load testing.
  # Was: protect_from_forgery with: :exception
  protect_from_forgery with: :null_session

  before_action :set_phase
  before_action :change_default_caching_policy

  def set_phase
    @phase = :released
  end

  # * Set cache control headers for HMLR apps to be public and cacheable
  # * Price Paid Data uses a time limit of 5 minutes (300 seconds)
  # Sets the default `Cache-Control` header for all requests,
  # unless overridden in the action
  def change_default_caching_policy
    expires_in 5.minutes, public: true, must_revalidate: true if Rails.env.production?
  end

  # Handle specific types of exceptions and render the appropriate error page
  # or attempt to render a generic error page if no specific error page exists
  unless Rails.application.config.consider_all_requests_local
    rescue_from StandardError do |e|
      # Trigger the appropriate error handling method based on the exception
      case e.class
      when ActionController::RoutingError, ActionView::MissingTemplate
        :render404
      when ActionController::InvalidCrossOriginRequest
        :render403
      when ActionController::BadRequest, ActionController::ParameterMissing
        :render400
      else
        :handle_internal_error
      end
    end
  end

  # Render the appropriate error page based on the exception
  def handle_internal_error(exception)
    if exception.instance_of? ArgumentError
      render_error(400)
    else
      Rails.logger.warn "No explicit error page for exception #{exception} - #{exception.class}"
      # Instrument ActiveSupport::Notifications for internal server errors only:
      sentry_code = instrument_internal_error(exception)
      render_error(500, sentry_code)
    end
  end

  def render_400(_exception = nil) # rubocop:disable Naming/VariableNumber
    render_error(400)
  end

  def render_403(_exception = nil) # rubocop:disable Naming/VariableNumber
    render_error(403)
  end

  def render_404(_exception = nil) # rubocop:disable Naming/VariableNumber
    render_error(404)
  end

  def render_500(_exception = nil) # rubocop:disable Naming/VariableNumber
    render_error(500)
  end

  def render_error(status, sentry_code = nil)
    reset_response

    error_status = Rack::Utils::SYMBOL_TO_STATUS_CODE[status] || status
    respond_to do |format|
      format.html { render_html_error_page(error_status, sentry_code) }
      # Anything else returns the status as human readable plain string
      format.all { render plain: Rack::Utils::HTTP_STATUS_CODES[error_status].to_s, status: error_status }
    end
  end

  def render_html_error_page(status, sentry_code)
    render 'exceptions/error_page',
           layout: true,
           locals: { status: status, sentry_code: sentry_code },
           status: status
  end

  def reset_response
    self.response_body = nil
  end

  # Notify subscriber(s) of an internal error event with the payload of the
  # exception once done
  # @param [exc] exp the exception that caused the error
  # @return [ActiveSupport::Notifications::Event] provides an object-oriented
  # interface to the event
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def instrument_internal_error(exc, status = nil)
    err = {
      message: exc&.message || exc,
      status: exc&.status || Rack::Utils::SYMBOL_TO_STATUS_CODE[exc]
    }
    err[:status] = status if status
    err[:type] = exc.class&.name if exc&.class
    err[:cause] = exc&.cause if exc&.cause
    err[:backtrace] = exc&.backtrace if exc&.backtrace && Rails.env.development?
    # Log the exception to the Rails logger with the appropriate severity
    Rails.logger.send(err[:status] < 500 ? :warn : :error, err)
    # Return unless the status code is 500 or greater to ensure subscribers are NOT notified
    return unless err[:status] >= 500

    sevent = Sentry.capture_exception(exc) unless Rails.env.development?
    # Instrument the internal error event to notify subscribers of the error
    ActiveSupport::Notifications.instrument('internal_error.application', exception: err)
    # Return the event id for the internal error event
    sevent&.event_id
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
end
