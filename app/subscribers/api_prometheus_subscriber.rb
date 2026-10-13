# frozen_string_literal: true

# Records metrics for Data Services API interactions. Logging for the same events
# is ApiRequestLogSubscriber's job, so this subscriber does not log.
#
# Label values are bounded on purpose: every distinct value is a new time series,
# so an exception's own message, which can carry a URL or user input, is never
# used. The label is called `message` because the alert rules, which are shared
# between applications, show `{{ $labels.message }}`.
class ApiPrometheusSubscriber < ActiveSupport::Subscriber
  attach_to :data_services_api

  def response(event)
    response = event.payload[:response]
    duration = event.payload[:duration]

    Prometheus::Client.registry
                      .get(:api_status)
                      .increment(labels: { status: response.status.to_s })
    Prometheus::Client.registry
                      .get(:api_requests)
                      .increment(labels: { result: 'success' })
    Prometheus::Client.registry
                      .get(:api_response_times)
                      .observe(duration.to_i)
  end

  # The API could not be reached, or did not answer in time
  def connection_failure(event)
    count_failed_request
    Prometheus::Client.registry
                      .get(:api_connection_failure)
                      .increment(labels: { message: event.payload[:exception].class.name })
  end

  # The API answered, but with an error status or a body that could not be read
  def service_exception(event)
    status = event.payload[:exception].try(:status)
    message = status ? "HTTP #{status}" : 'no response status'

    count_failed_request
    Prometheus::Client.registry
                      .get(:api_service_exception)
                      .increment(labels: { message: message })
  end

  private

  def count_failed_request
    Prometheus::Client.registry
                      .get(:api_requests)
                      .increment(labels: { result: 'failure' })
  end
end
