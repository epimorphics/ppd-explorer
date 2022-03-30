# frozen_string_literal: true

# Subscribe to :application events
class ApplicationPrometheusSubscriber < ActiveSupport::Subscriber
  attach_to :application

  def internal_error(event)
    message = event.payload[:exception]
    Prometheus::Metrics[:internal_application_error].increment(labels: { message: message.to_s })
  end
end
