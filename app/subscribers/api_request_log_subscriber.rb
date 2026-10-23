# frozen_string_literal: true

# Logs every interaction with the Data Services API, once, from the gem's own
# instrumentation. Models and controllers should not log API calls themselves:
# doing so duplicates these entries and drifts out of step with the gem's retry
# behaviour.
#
# The API's values go in `upstream_*` fields, so that `status`, `path` and
# `request_time` keep meaning the incoming request, whose own received and
# completed entries are logged by epilog_rails. request_status is always
# 'processing': a call to the API is a step in handling that request.
#
# Failures are WARN: this subscriber can't know whether the request will recover,
# so the ERROR belongs to the request's completed entry.
class ApiRequestLogSubscriber < ActiveSupport::Subscriber
  attach_to :data_services_api

  # The most of the API's response body logged with a failure: enough for its
  # error message, without letting a large page flood the log
  RESPONSE_EXCERPT_LENGTH = 500

  def request(event)
    Rails.logger.info(
      {
        message: "Calling API: #{method_and_path(event.payload)}",
        **upstream_call(event.payload),
        request_status: 'processing'
      }.compact
    )
  end

  def response(event)
    response = event.payload[:response]
    url = response.env.url
    path = url.query ? "#{url.path}?#{url.query}" : url.path
    method = response.env.method.to_s.upcase
    time = seconds(event.payload[:duration])
    # Only array bodies have a row count; an explain query returns a Hash, and
    # claiming "0 rows" for one would be misleading.
    returned_rows = response.body.size if response.body.is_a?(Array)
    call = "#{method} #{path}"

    Rails.logger.info(
      {
        message: "API #{outcome(returned_rows)} #{call} (status #{response.status}, #{time}s)",
        upstream_url: upstream_url,
        upstream_method: method,
        upstream_path: path,
        upstream_status: response.status,
        upstream_time: time,
        returned_rows: returned_rows,
        request_status: 'processing'
      }.compact
    )
  end

  # The gem is about to try the request again
  def retry(event)
    exception = event.payload[:exception]
    delay = event.payload[:will_retry_in].round(2)

    Rails.logger.warn(
      {
        message: "Retrying API request #{method_and_path(event.payload)} " \
                 "in #{delay}s (attempt #{event.payload[:retry_count]}): #{exception.message}",
        **upstream_call(event.payload),
        retry_count: event.payload[:retry_count],
        exception: exception.class.name,
        request_status: 'processing'
      }.compact
    )
  end

  # The API could not be reached, or did not answer in time, after any retries.
  # No response arrived, so no status is logged, whatever the payload says: the
  # gem always sends a 503 here.
  def connection_failure(event)
    call = method_and_path(event.payload)
    time = seconds(event.payload[:duration])
    exception = event.payload[:exception]
    message = if exception.is_a?(Faraday::TimeoutError)
                "API did not respond in time to #{call} (#{time}s): #{exception.message}"
              else
                "Could not connect to the API for #{call} (#{time}s): #{exception.message}"
              end

    log_failure(event, message, status: nil)
  end

  # The API answered, but with an error status or a body that could not be read.
  # Only a 4xx or 5xx is an error status: the gem also raises when a 2xx body is
  # not valid JSON, such as one cut off part way, and that is not the API
  # returning an error.
  def service_exception(event)
    status = event.payload[:status]
    exception = event.payload[:exception]

    log_failure(event, service_exception_message(event.payload, status, exception),
                status: status, response: excerpt(exception.try(:service_message)))
  end

  private

  def service_exception_message(payload, status, exception)
    call = method_and_path(payload)
    time = seconds(payload[:duration])
    return "API returned status #{status} for #{call} (#{time}s)" if status.to_i >= 400

    timing = status ? "status #{status}, #{time}s" : "#{time}s"
    "API response to #{call} could not be read (#{timing}): #{exception.message}"
  end

  def log_failure(event, message, status:, response: nil)
    Rails.logger.warn(
      {
        message: message,
        **upstream_call(event.payload),
        upstream_status: status,
        upstream_time: seconds(event.payload[:duration]),
        upstream_response: response,
        exception: event.payload[:exception].class.name,
        request_status: 'processing'
      }.compact
    )
  end

  # The start of a response body, which may already have been parsed. A JSON body,
  # such as the API's pretty-printed error, is logged compactly, so the excerpt is
  # spent on content rather than whitespace.
  def excerpt(body)
    text = body.is_a?(String) ? compact_json(body) : body&.to_json
    text.presence&.truncate(RESPONSE_EXCERPT_LENGTH)
  end

  # The body re-encoded without whitespace if it is JSON, otherwise unchanged
  def compact_json(body)
    JSON.parse(body).to_json
  rescue JSON::ParserError
    body
  end

  def upstream_call(payload)
    {
      upstream_url: upstream_url,
      upstream_method: upstream_method(payload),
      upstream_path: path_with_query(payload)
    }
  end

  def method_and_path(payload)
    "#{upstream_method(payload)} #{path_with_query(payload)}"
  end

  # The gem only makes GET requests, and only its retry event says so
  def upstream_method(payload)
    payload[:method] || 'GET'
  end

  def path_with_query(payload)
    payload[:query_string].present? ? "#{payload[:path]}?#{payload[:query_string]}" : payload[:path]
  end

  def outcome(returned_rows)
    return 'responded to' unless returned_rows

    "returned #{returned_rows} row#{'s' unless returned_rows == 1} for"
  end

  # Scheme, host and port. A malformed URL is logged as configured: logging must
  # not raise.
  def upstream_url
    url = Rails.application.config.api_service_url
    return if url.blank?

    uri = URI.parse(url)
    return url unless uri.host

    port = ":#{uri.port}" unless uri.port == uri.default_port
    "#{uri.scheme}://#{uri.host}#{port}"
  rescue URI::InvalidURIError
    url
  end

  def seconds(milliseconds)
    (milliseconds / 1000.0).round(3) if milliseconds
  end
end
