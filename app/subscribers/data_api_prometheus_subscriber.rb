# frozen_string_literal: true

# Subscribe to :data_api events
class DataApiPrometheusSubscriber < ActiveSupport::Subscriber
  attach_to :data_api

  def response(event)
    response = event.payload[:response]

    Prometheus::Metrics[:data_api_status].increment(labels: { status: response.status.to_s })
  end

  def connection_failure(_event)
    Prometheus::Metrics[:data_api_connection_failure].increment
  end

  def service_exception(_event)
    Prometheus::Metrics[:data_api_service_exception].increment
  end
end
