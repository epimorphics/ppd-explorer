# frozen_string_literal: true

# Renders the error pages. Reached only through `config.exceptions_app` (see
# config/application.rb), never through a route, so every request here carries
# the exception Rails caught.
#
# This controller renders. It does not decide which error occurred or what status
# it deserves: Rails has already done both, via `rescue_responses`, and passes the
# status as the request path.
class ErrorsController < ApplicationController
  # The failed request may have been a form POST, and its token is not ours to
  # check. A CSRF failure here would abandon the error page for Rails' bare
  # failsafe response.
  skip_forgery_protection

  # Error pages must not be served from a shared cache after the fault is fixed.
  skip_before_action :change_default_caching_policy

  PARSED_PARAMS = {
    'action_dispatch.request.query_parameters' => :GET,
    'action_dispatch.request.request_parameters' => :POST
  }.freeze

  # The Rack entry point for `config.exceptions_app`.
  #
  # Rails reads the request's params while processing any controller action, before
  # the action runs. When the error being reported is that the params could not be
  # parsed, such as a malformed query string, that read raises again, and
  # ShowExceptions gives up and returns its plain-text failsafe 500. So treat params
  # that cannot be parsed as empty here: Request caches parsed params in these
  # headers, and a cached empty hash is never re-parsed.
  def self.render_error(env)
    request = ActionDispatch::Request.new(env)
    PARSED_PARAMS.each do |header, parse|
      request.public_send(parse)
    rescue ActionController::BadRequest
      env[header] = {}
    end

    action(:show).call(env)
  end

  def show
    status = Rack::Utils.status_code(request.path_info.delete_prefix('/').to_i)
    exception = request.get_header('action_dispatch.exception')

    instrument_internal_error(exception, status)

    respond_to do |format|
      format.html do
        render 'exceptions/error_page',
               locals: { status: status, message: user_message(exception), sentry_code: nil },
               status: status
      end
      format.all { render plain: Rack::Utils::HTTP_STATUS_CODES[status].to_s, status: status }
    end
  end

  private

  # Only a malformed search explains itself to the user. Any other exception's
  # message is for the logs and Sentry, not the page.
  def user_message(exception)
    exception.message if exception.is_a?(MalformedSearchError)
  end

  # Feeds the `internal_application_error` Prometheus counter. Only a 500 is an
  # internal error: 502, 503 and 504 are failures of the Data Services API (see
  # `rescue_responses` in config/application.rb), which the api_* metrics count.
  def instrument_internal_error(exception, status)
    return unless status == 500

    ActiveSupport::Notifications.instrument(
      'internal_error.application',
      exception: {
        class: exception.class.name,
        action: failed_action,
        message: exception.message,
        status: status
      }
    )
  end

  # The action that failed, such as "search#index". Absent when no route matched.
  def failed_action
    request.path_parameters.values_at(:controller, :action).compact.join('#').presence
  end
end
