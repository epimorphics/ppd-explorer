# frozen_string_literal: true

registry = Prometheus::Client.registry

# Prometheus counters
registry.counter(
  :api_status,
  docstring: 'Response from back-end API',
  labels: [:status]
)
registry.counter(
  :api_requests,
  docstring: 'Overall count of back-end API requests',
  labels: [:result]
)
registry.counter(
  :api_connection_failure,
  docstring: 'Reasons for back-end API connection failure',
  labels: [:message]
)
registry.counter(
  :api_service_exception,
  docstring: 'The response from the back-end data API was not processed',
  labels: [:message]
)
registry.counter(
  :internal_application_error,
  docstring: 'Unexpected events and internal error count',
  labels: [:message]
)

# Prometheus gauges
registry.gauge(
  :memory_used_mb,
  docstring: 'Process memory usage in mb'
)

# Prometheus histograms
registry.histogram(
  :api_response_times,
  docstring: 'Histogram of response times for API requests',
  buckets: Prometheus::Client::Histogram.exponential_buckets(start: 0.005, count: 16)
)
