# frozen_string_literal: true

require 'test_helper'
require 'stringio'

# Unit tests on the ApiPrometheusSubscriber class
class ApiPrometheusSubscriberTest < ActiveSupport::TestCase
  # Real logger (the app's actual JsonRailsLogger::Logger), not a Mocha stub: a
  # stub bypasses Ruby's actual method arity, which is exactly what let the
  # two-positional-argument Rails.logger.error call ship broken (Logger#error
  # only accepts 0-1 positional args). Using the real logger here means a
  # regression back to that call shape raises ArgumentError in the test, the
  # same way it did in production, and also verifies the Hash we pass is
  # actually shaped the way JsonRailsLogger::JsonFormatter expects.
  def with_captured_logger
    output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = JsonRailsLogger::Logger.new(output)
    yield
    output.string.lines.map { |line| JSON.parse(line) }
  ensure
    Rails.logger = original_logger
  end

  describe 'ApiPrometheusSubscriber' do
    describe '#connection_failure' do
      it 'should increment the failure counters and log an error' do
        exception = Faraday::ConnectionFailed.new('Failed to open TCP connection to data-api:8080')
        event = stub(payload: { exception: exception })

        Prometheus::Client.registry.get(:api_requests).expects(:increment).with(labels: { result: 'failure' })
        Prometheus::Client.registry.get(:api_connection_failure).expects(:increment)
                          .with(labels: { message: exception.to_s })

        logged = with_captured_logger { ApiPrometheusSubscriber.new.connection_failure(event) }

        _(logged.size).must_equal 1
        _(logged.first['message']).must_equal(
          "API connection failure: #{exception.message} - Faraday::ConnectionFailed"
        )
        _(logged.first['request_status']).must_equal 'error'
        _(logged.first['status']).must_equal 503
      end
    end

    describe '#service_exception' do
      it 'should increment the exception counter and log an error' do
        exception = StandardError.new('Unexpected response from data-api')
        event = stub(payload: { exception: exception })

        Prometheus::Client.registry.get(:api_service_exception).expects(:increment)
                          .with(labels: { message: exception.to_s })

        logged = with_captured_logger { ApiPrometheusSubscriber.new.service_exception(event) }

        _(logged.size).must_equal 1
        _(logged.first['message']).must_equal(
          "API service exception: #{exception.message} - StandardError"
        )
        _(logged.first['request_status']).must_equal 'error'
        _(logged.first['status']).must_equal 502
      end
    end
  end
end
