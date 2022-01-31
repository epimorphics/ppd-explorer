# frozen_string_literal: true

# Prometheus counters
Prometheus::Metrics.register_metric(
  Prometheus::Client::Counter, :data_api_status, 'Response from data API', [:status]
)
Prometheus::Metrics.register_metric(
  Prometheus::Client::Counter, :data_api_connection_failure, 'Could not connect to back-end data API'
)
Prometheus::Metrics.register_metric(
  Prometheus::Client::Counter, :data_api_service_exception, 'The response from the back-end data API was not processed'
)
Prometheus::Metrics.register_metric(
  Prometheus::Client::Counter, :internal_application_error, 'Unexpected events and internal error count'
)

# Prometheus gauges
Prometheus::Metrics.register_metric(
  Prometheus::Client::Gauge, :memory_used_mb, 'Process memory usage in mb'
)
