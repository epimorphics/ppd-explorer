# frozen_string_literal: true

require 'test_helper'
require 'stringio'

# Unit tests on the ApiRequestLogSubscriber class
class ApiRequestLogSubscriberTest < ActiveSupport::TestCase
  # A real logger with the app's actual formatter, not a Mocha stub: a stub would
  # accept a call the real Logger rejects, and would not show what is written.
  def logged
    output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(output).tap do |logger|
      logger.formatter = EpilogRails::JsonFormatter.new
    end
    yield
    output.string.lines.map { |line| JSON.parse(line).except('ts') }
  ensure
    Rails.logger = original_logger
  end

  def subscriber
    ApiRequestLogSubscriber.new
  end

  describe 'ApiRequestLogSubscriber' do
    describe '#request' do
      it 'should log the path with its query string' do
        event = stub(payload: { path: '/landregistry/id/ppd', query_string: '_limit=1' })

        _(logged { subscriber.request(event) }).must_equal [{
          'level' => 'INFO',
          'message' => 'Calling API: /landregistry/id/ppd?_limit=1',
          'path' => '/landregistry/id/ppd?_limit=1',
          'request_status' => 'processing'
        }]
      end

      it 'should log the bare path when there is no query string' do
        event = stub(payload: { path: '/landregistry/id/ppd', query_string: nil })

        _(logged { subscriber.request(event) }.first['path']).must_equal '/landregistry/id/ppd'
      end
    end

    describe '#response' do
      def response_event(body:, duration:, query: '_limit=100')
        url = stub(path: '/landregistry/id/ppd', query: query)
        response = stub(env: stub(url: url, method: :get), status: 200, body: body)
        stub(payload: { response: response, duration: duration })
      end

      it 'should log the row count, path and timing' do
        event = response_event(body: [{}, {}], duration: 1233)

        _(logged { subscriber.response(event) }).must_equal [{
          'level' => 'INFO',
          'message' => 'API returned 2 rows, time taken: 1233 ms',
          'method' => 'GET',
          'path' => '/landregistry/id/ppd?_limit=100',
          'request_status' => 'processing',
          'request_time' => 1.233,
          'returned_rows' => 2,
          'status' => 200
        }]
      end

      it 'should not pluralise a single row' do
        event = response_event(body: [{}], duration: 5)

        _(logged { subscriber.response(event) }.first['message']).must_equal 'API returned 1 row, time taken: 5 ms'
      end

      it 'should not claim a row count when the response body is not a list' do
        event = response_event(body: { 'sparql' => 'SELECT' }, duration: 5, query: nil)
        entry = logged { subscriber.response(event) }.first

        _(entry['message']).must_equal 'API responded, time taken: 5 ms'
        _(entry['path']).must_equal '/landregistry/id/ppd'
        _(entry.key?('returned_rows')).must_equal false
      end
    end

    describe '#retry' do
      it 'should warn with the exception, attempt and delay' do
        exception = Faraday::ConnectionFailed.new('Failed to open TCP connection to data-api:8080')
        event = stub(payload: { path: '/landregistry/id/ppd', method: 'GET', retry_count: 2,
                                exception: exception, will_retry_in: 1.084 })

        _(logged { subscriber.retry(event) }).must_equal [{
          'level' => 'WARN',
          'message' => 'Retrying API request after Faraday::ConnectionFailed: ' \
                       'Failed to open TCP connection to data-api:8080 (attempt 2, retrying in 1.08s)',
          'method' => 'GET',
          'path' => '/landregistry/id/ppd',
          'request_status' => 'processing'
        }]
      end
    end

    describe '#connection_failure' do
      it 'should log an error with the path, time taken and status' do
        exception = Faraday::ConnectionFailed.new('Failed to open TCP connection to data-api:8080')
        event = stub(payload: { exception: exception, path: '/landregistry/id/ppd',
                                query_string: '_limit=100', duration: 2500, status: 503 })

        _(logged { subscriber.connection_failure(event) }).must_equal [{
          'level' => 'ERROR',
          'message' => 'API connection failure: Failed to open TCP connection to data-api:8080 ' \
                       '- Faraday::ConnectionFailed',
          'path' => '/landregistry/id/ppd?_limit=100',
          'request_status' => 'processing',
          'request_time' => 2.5,
          'status' => 503
        }]
      end
    end

    describe '#service_exception' do
      it 'should log an error with the status the API returned' do
        exception = DataServicesApi::ServiceException.new('the server responded with status 503', 503)
        event = stub(payload: { exception: exception, path: '/landregistry/id/ppd',
                                query_string: nil, duration: 90_000, status: 503 })

        _(logged { subscriber.service_exception(event) }).must_equal [{
          'level' => 'ERROR',
          'message' => 'API service exception: the server responded with status 503 ' \
                       '- DataServicesApi::ServiceException',
          'path' => '/landregistry/id/ppd',
          'request_status' => 'processing',
          'request_time' => 90.0,
          'status' => 503
        }]
      end

      it 'should omit the status when the API gave none' do
        exception = DataServicesApi::ServiceException.new('unexpected token', nil)
        event = stub(payload: { exception: exception, path: '/landregistry/id/ppd',
                                query_string: nil, duration: 10, status: nil })

        _(logged { subscriber.service_exception(event) }.first.key?('status')).must_equal false
      end
    end

    # Fired through the real notification bus, so a renamed event fails here
    describe 'ActiveSupport::Notifications wiring' do
      it 'should log a retry when the gem reports one' do
        exception = Faraday::TimeoutError.new('execution expired')
        payload = { path: '/landregistry/id/ppd', method: 'GET', retry_count: 1,
                    exception: exception, will_retry_in: 0.25 }

        entries = logged { ActiveSupport::Notifications.instrument('retry.data_services_api', payload) }

        _(entries.size).must_equal 1
        _(entries.first['level']).must_equal 'WARN'
      end
    end
  end
end
