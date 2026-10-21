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

  # The fields every entry about an API call carries
  def upstream_call(path)
    {
      'upstream_url' => 'http://data-api:8080',
      'upstream_method' => 'GET',
      'upstream_path' => path,
      'request_status' => 'processing'
    }
  end

  describe 'ApiRequestLogSubscriber' do
    before do
      @original_url = Rails.application.config.api_service_url
      Rails.application.config.api_service_url = 'http://data-api:8080/'
    end

    after { Rails.application.config.api_service_url = @original_url }

    describe '#request' do
      it 'should log the method and path with its query string' do
        event = stub(payload: { path: '/landregistry/id/ppd', query_string: '_limit=1' })

        _(logged { subscriber.request(event) }).must_equal [{
          'level' => 'INFO',
          'message' => 'Calling API: GET /landregistry/id/ppd?_limit=1',
          **upstream_call('/landregistry/id/ppd?_limit=1')
        }]
      end

      it 'should log the bare path when there is no query string' do
        event = stub(payload: { path: '/landregistry/id/ppd', query_string: nil })

        _(logged { subscriber.request(event) }.first['upstream_path']).must_equal '/landregistry/id/ppd'
      end
    end

    describe '#response' do
      def response_event(body:, duration:, query: '_limit=100')
        url = stub(path: '/landregistry/id/ppd', query: query)
        response = stub(env: stub(url: url, method: :get), status: 200, body: body)
        stub(payload: { response: response, duration: duration })
      end

      it 'should log the row count, call, status and timing in upstream fields' do
        event = response_event(body: [{}, {}], duration: 1233)

        _(logged { subscriber.response(event) }).must_equal [{
          'level' => 'INFO',
          'message' => 'API returned 2 rows for GET /landregistry/id/ppd?_limit=100 (status 200, 1.233s)',
          **upstream_call('/landregistry/id/ppd?_limit=100'),
          'upstream_status' => 200,
          'upstream_time' => 1.233,
          'returned_rows' => 2
        }]
      end

      it 'should not pluralise a single row' do
        event = response_event(body: [{}], duration: 5)

        _(logged { subscriber.response(event) }.first['message'])
          .must_equal 'API returned 1 row for GET /landregistry/id/ppd?_limit=100 (status 200, 0.005s)'
      end

      it 'should not claim a row count when the response body is not a list' do
        event = response_event(body: { 'sparql' => 'SELECT' }, duration: 5, query: nil)
        entry = logged { subscriber.response(event) }.first

        _(entry['message']).must_equal 'API responded to GET /landregistry/id/ppd (status 200, 0.005s)'
        _(entry['upstream_path']).must_equal '/landregistry/id/ppd'
        _(entry.key?('returned_rows')).must_equal false
      end
    end

    describe '#retry' do
      it 'should warn with the call, delay, attempt and exception' do
        exception = Faraday::ConnectionFailed.new('Failed to open TCP connection to data-api:8080')
        event = stub(payload: { path: '/landregistry/id/ppd', method: 'GET', retry_count: 2,
                                exception: exception, will_retry_in: 1.084 })

        _(logged { subscriber.retry(event) }).must_equal [{
          'level' => 'WARN',
          'message' => 'Retrying API request GET /landregistry/id/ppd in 1.08s (attempt 2): ' \
                       'Failed to open TCP connection to data-api:8080',
          **upstream_call('/landregistry/id/ppd'),
          'retry_count' => 2,
          'exception' => 'Faraday::ConnectionFailed'
        }]
      end
    end

    describe '#connection_failure' do
      def failure_event(exception)
        # The gem always sends status 503 here, although no response arrived
        stub(payload: { exception: exception, path: '/landregistry/id/ppd',
                        query_string: '_limit=100', duration: 2500, status: 503 })
      end

      it 'should warn with the call and time taken, and no status' do
        exception = Faraday::ConnectionFailed.new('Failed to open TCP connection to data-api:8080')

        _(logged { subscriber.connection_failure(failure_event(exception)) }).must_equal [{
          'level' => 'WARN',
          'message' => 'Could not connect to the API for GET /landregistry/id/ppd?_limit=100 (2.5s): ' \
                       'Failed to open TCP connection to data-api:8080',
          **upstream_call('/landregistry/id/ppd?_limit=100'),
          'upstream_time' => 2.5,
          'exception' => 'Faraday::ConnectionFailed'
        }]
      end

      it 'should say when the API did not answer in time' do
        exception = Faraday::TimeoutError.new('execution expired')
        entry = logged { subscriber.connection_failure(failure_event(exception)) }.first

        _(entry['message'])
          .must_equal 'API did not respond in time to GET /landregistry/id/ppd?_limit=100 (2.5s): execution expired'
        _(entry['exception']).must_equal 'Faraday::TimeoutError'
        _(entry.key?('upstream_status')).must_equal false
      end
    end

    describe '#service_exception' do
      it 'should warn with the status the API returned' do
        exception = DataServicesApi::ServiceException.new('the server responded with status 503', 503)
        event = stub(payload: { exception: exception, path: '/landregistry/id/ppd',
                                query_string: nil, duration: 90_000, status: 503 })

        _(logged { subscriber.service_exception(event) }).must_equal [{
          'level' => 'WARN',
          'message' => 'API returned an error for GET /landregistry/id/ppd (status 503, 90.0s)',
          **upstream_call('/landregistry/id/ppd'),
          'upstream_status' => 503,
          'upstream_time' => 90.0,
          'exception' => 'DataServicesApi::ServiceException'
        }]
      end

      it 'should say the response could not be read when the API gave no status' do
        exception = DataServicesApi::ServiceException.new('unexpected token', nil)
        event = stub(payload: { exception: exception, path: '/landregistry/id/ppd',
                                query_string: nil, duration: 10, status: nil })
        entry = logged { subscriber.service_exception(event) }.first

        _(entry['message'])
          .must_equal 'API response to GET /landregistry/id/ppd could not be read (0.01s): unexpected token'
        _(entry.key?('upstream_status')).must_equal false
      end
    end

    describe 'upstream_url' do
      def logged_url
        event = stub(payload: { path: '/landregistry/id/ppd', query_string: nil })
        logged { subscriber.request(event) }.first['upstream_url']
      end

      it 'should keep a port that is not the default' do
        _(logged_url).must_equal 'http://data-api:8080'
      end

      it 'should drop a default port and any path' do
        Rails.application.config.api_service_url = 'https://data-api.example.com:443/base'

        _(logged_url).must_equal 'https://data-api.example.com'
      end

      it 'should log a malformed URL as configured, rather than raise' do
        Rails.application.config.api_service_url = 'not a url'

        _(logged_url).must_equal 'not a url'
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
