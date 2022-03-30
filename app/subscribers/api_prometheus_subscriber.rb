# frozen_string_literal: true

# Subscribe to :data_api events
class ApiPrometheusSubscriber < ActiveSupport::Subscriber
  attach_to :api

  def response(event)
    response = event.payload[:response]
    duration = event.payload[:duration]

    Prometheus::Metrics[:api_status].increment(labels: { status: response.status.to_s })
    Prometheus::Metrics[:api_requests].increment(labels: { succeeded: true })
    Prometheus::Metrics[:api_response_times].observe(duration)
  end

  def connection_failure(event)
    message = event.payload[:exception]
    Prometheus::Metrics[:api_requests].increment(labels: { succeeded: false })
    Prometheus::Metrics[:api_connection_failure].increment(labels: { message: message.to_s })
  end

  def service_exception(event)
    message = event.payload[:exception]
    Prometheus::Metrics[:api_service_exception].increment(labels: { message: message.to_s })
  end
end
