# frozen_string_literal: true

# Prometheus counters
Prometheus::Metrics.register_metric(
  Prometheus::Client::Counter,
  :api_status,
  'Response from back-end API',
  labels: [:status]
)
Prometheus::Metrics.register_metric(
  Prometheus::Client::Counter,
  :api_requests,
  'Overall count of back-end API requests',
  labels: [:succeeded]
)
Prometheus::Metrics.register_metric(
  Prometheus::Client::Counter,
  :api_connection_failure,
  'Reasons for back-end API connection failure',
  labels: [:message]
)
Prometheus::Metrics.register_metric(
  Prometheus::Client::Counter,
  :api_service_exception,
  'The response from the back-end data API was not processed',
  labels: [:message]
)
Prometheus::Metrics.register_metric(
  Prometheus::Client::Counter,
  :internal_application_error,
  'Unexpected events and internal error count',
  labels: [:message]
)

# Prometheus gauges
Prometheus::Metrics.register_metric(
  Prometheus::Client::Gauge,
  :memory_used_mb,
  'Process memory usage in mb'
)

# Prometheus histograms
Prometheus::Metrics.register_metric(
  Prometheus::Client::Histogram,
  :api_response_times,
  'Histogram of response times for API requests',
  buckets: Prometheus::Client::Histogram.exponential_buckets(start: 0.005, count: 16)
)
