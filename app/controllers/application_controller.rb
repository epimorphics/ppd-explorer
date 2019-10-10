# frozen_string_literal: true

# :nodoc:
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_phase
  def set_phase
    @phase = :released
  end

  around_action :log_request_result
  def log_request_result
    start = Time.now
    yield
    duration = Time.now - start
    detailed_request_log(duration)
  end

  unless Rails.application.config.consider_all_requests_local
    rescue_from ActionController::RoutingError, with: :render_404
    rescue_from ActionController::InvalidCrossOriginRequest, with: :render_403
    rescue_from Exception, with: :render_exception
  end

  private

  def render_exception(exception)
    if exception.instance_of? ArgumentError
      render_error(400)
    elsif exception.instance_of? ActionController::InvalidCrossOriginRequest
      render_error(403)
    else
      Rails.logger.warn "No explicit error page for exception #{exception} - #{exception.class}"
      render_error(500)
    end
  end

  def render_404(_exception = nil)
    render_error(404)
  end

  def render_403(_exception = nil)
    render_error(403)
  end

  def render_error(status)
    reset_response

    respond_to do |format|
      format.html { render_html_error_page(status) }
      format.all do
        render nothing: true, status: status
      end
    end
  end

  def render_html_error_page(status)
    render(layout: false,
           file: Rails.root.join('public', 'landing', status.to_s),
           status: status)
  end

  def reset_response
    self.response_body = nil
  end

  def detailed_request_log(duration) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    env = request.env

    log_fields = {
      timeTakenMS: duration * 1_000,
      requestPath: env['REQUEST_PATH'],
      queryString: env['QUERY_STRING'],
      httpUserAgent: env['HTTP_USER_AGENT'],
      xRequestID: env['X_REQUEST_ID'],
      xForwardedFor: env['X_FORWARDED_FOR'],
      body: request.body.gets&.gsub("\n", '\n'),
      responseStatus: response.status
    }

    Rails.logger.debug(JSON.generate(log_fields))
  end
end
