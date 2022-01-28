# frozen_string_literal: true

Prometheus::Metrics.register_metric(
  Prometheus::Client::Counter, :data_api_status, 'Response from data API', [:status]
)
Prometheus::Metrics.register_metric(
  Prometheus::Client::Counter, :data_api_connection_failure, 'Could not connect to back-end data API'
)
Prometheus::Metrics.register_metric(
  Prometheus::Client::Gauge, :memory_used_mb, 'Process memory usage in mb'
)
Prometheus::Metrics.register_metric(
  Prometheus::Client::Counter, :internal_application_error, 'Unexpected events and internal error count'
)
