# frozen_string_literal: true

# Subscribe to :application events
class ApplicationPrometheusSubscriber < ActiveSupport::Subscriber
  attach_to :application

  def internal_error(_event)
    Prometheus::Metrics[:internal_application_error].increment
  end
end
