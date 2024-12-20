# frozen_string_literal: true

# Subscribe to :application events
class ApplicationPrometheusSubscriber < ActiveSupport::Subscriber
  attach_to :application

  def internal_error(event)
    error = event.payload[:exception]
    Prometheus::Client.registry
                      .get(:internal_application_error)
                      .increment(labels: { result: 'failure', message: "#{error[:type]}: #{error[:message]}", status: error[:status].to_i }) # rubocop:disable Layout/LineLength
  end
end
