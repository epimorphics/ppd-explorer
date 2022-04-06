# frozen_string_literal: true

# Subscribe to `*.action_controller`` events
#
# Note: This is Rails 5 specific. In Rails 6, we'd subscribe to
# `request.action_dispatch`
class ActionControllerPrometheusSubscriber < ActiveSupport::Subscriber
  attach_to :action_controller

  def process_action(_event)
    mem = GetProcessMem.new

    Prometheus::Client.registry
                      .get(:memory_used_mb)
                      .set(mem.mb)
  end
end
