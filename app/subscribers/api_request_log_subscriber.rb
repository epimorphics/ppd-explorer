# frozen_string_literal: true

# Logs every interaction with the Data Services API, once, from the gem's own
# instrumentation. Models and controllers should not log API calls themselves:
# doing so duplicates these entries and drifts out of step with the gem's retry
# behaviour.
#
# request_status is always 'processing': a call to the API is a step in handling
# the incoming request, whose own received and completed entries are logged by
# epilog_rails.
class ApiRequestLogSubscriber < ActiveSupport::Subscriber
  attach_to :data_services_api

  def request(event)
    path = path_with_query(event.payload)

    Rails.logger.info(
      message: "Calling API: #{path}",
      path: path,
      request_status: 'processing'
    )
  end

  def response(event)
    response = event.payload[:response]
    duration = event.payload[:duration]
    url = response.env.url
    # Only array bodies have a row count; an explain query returns a Hash, and
    # claiming "0 rows" for one would be misleading.
    returned_rows = response.body.size if response.body.is_a?(Array)

    Rails.logger.info(
      {
        message: "#{response_summary(returned_rows)}, time taken: #{duration} ms",
        method: response.env.method.to_s.upcase,
        path: url.query ? "#{url.path}?#{url.query}" : url.path,
        request_status: 'processing',
        request_time: seconds(duration),
        returned_rows: returned_rows,
        status: response.status
      }.compact
    )
  end

  # WARN, not ERROR: a retry that is about to happen is recoverable.
  def retry(event)
    exception = event.payload[:exception]

    Rails.logger.warn(
      {
        message: "Retrying API request after #{exception.class.name}: #{exception.message} " \
                 "(attempt #{event.payload[:retry_count]}, " \
                 "retrying in #{event.payload[:will_retry_in].round(2)}s)",
        method: event.payload[:method],
        path: event.payload[:path],
        request_status: 'processing'
      }.compact
    )
  end

  # The API could not be reached, or did not answer in time, after any retries
  def connection_failure(event)
    exception = event.payload[:exception]

    log_failure(event, "API connection failure: #{exception.message} - #{exception.class.name}")
  end

  # The API answered, but with an error status or a body that could not be read
  def service_exception(event)
    exception = event.payload[:exception]

    log_failure(event, "API service exception: #{exception.message} - #{exception.class.name}")
  end

  private

  def log_failure(event, message)
    Rails.logger.error(
      {
        message: message,
        path: path_with_query(event.payload),
        request_status: 'processing',
        request_time: seconds(event.payload[:duration]),
        status: event.payload[:status]
      }.compact
    )
  end

  def path_with_query(payload)
    payload[:query_string].present? ? "#{payload[:path]}?#{payload[:query_string]}" : payload[:path]
  end

  def response_summary(returned_rows)
    return 'API responded' unless returned_rows

    "API returned #{returned_rows} row#{'s' unless returned_rows == 1}"
  end

  def seconds(milliseconds)
    (milliseconds / 1000.0).round(3) if milliseconds
  end
end
