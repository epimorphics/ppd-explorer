# frozen_string_literal: true

# Subscribe to `*.action_controller`` events
#
# Note: This is Rails 5 specific. In Rails 6, we'd subscribe to
# `request.action_dispatch`
class ActionControllerPrometheusSubscriber < ActiveSupport::Subscriber
  attach_to :action_controller

  # rubocop:disable Metric/AbcSize
  def process_action(_event)
    mem = GetProcessMem.new

    Prometheus::Client.registry
                      .get(:memory_used_mb)
                      .set(mem.mb)

    Prometheus::Client.registry
                      .get(:thread_count)
                      .set(Thread.list.select { |thread| %w[run sleep].include?(thread.status) }.count)

    Prometheus::Client.registry
                      .get(:process_threads)
                      .set(Thread.list.select { |thread| thread.status == 'run' }.count)
  end
  # rubocop:enable Metric/AbcSize
end
