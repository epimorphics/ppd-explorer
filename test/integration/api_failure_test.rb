# frozen_string_literal: true

require 'test_helper'
require 'stringio'

# A failing Data Services API call, followed all the way through the real
# data_services_api gem: only the HTTP connection is replaced. So these tests
# fail if the gem's exceptions or event names stop matching what the application
# registers and subscribes to.
class ApiFailureTest < ActionDispatch::IntegrationTest
  # Collect everything logged while the block runs, parsed from JSON
  def capture_log
    output = StringIO.new
    sink = ActiveSupport::Logger.new(output).tap do |logger|
      logger.formatter = EpilogRails::JsonFormatter.new
    end
    Rails.logger.broadcast_to(sink)
    yield
    output.string.lines.map { |line| JSON.parse(line) }
  ensure
    Rails.logger.stop_broadcasting_to(sink)
  end

  def metric(name, labels)
    Prometheus::Client.registry.get(name).get(labels: labels)
  end

  # The API wraps its rows as {"meta": …, "items": […]}, not as a bare array
  describe 'A successful Data Services API call' do
    before do
      body = { meta: { limit: 100 }, items: [] }.to_json
      stub_api_connection { [200, { 'Content-Type' => 'application/json' }, body] }
    end

    it 'should log the number of rows the API returned' do
      entries = capture_log { VCR.turned_off { get search_index_path(street: 'harbour road') } }
      responses = entries.select { |entry| entry.key?('returned_rows') }

      _(responses.size).must_equal 1
      _(responses.first['message']).must_match %r{\AAPI returned 0 rows for GET /landregistry/id/ppd\?}
      _(responses.first['returned_rows']).must_equal 0
    end
  end

  describe 'A failing Data Services API call' do
    before { @original_env = render_error_pages }
    after { Rails.application.env_config.merge!(@original_env) }

    describe 'when the API answers with a server error' do
      before { stub_api_connection { [503, {}, 'Query timed out'] } }

      it 'should respond with 503' do
        VCR.turned_off { get search_index_path(street: 'harbour road') }

        assert_response :service_unavailable
      end

      # The subscriber can't know whether the request will recover, so only the
      # request's completed entry is an ERROR
      it 'should log the failed call once as a warning, and the request once as an error' do
        entries = capture_log { VCR.turned_off { get search_index_path(street: 'harbour road') } }
        api_failures = entries.select { |entry| entry['message'].start_with?('API returned status 503') }
        errors = entries.select { |entry| entry['level'] == 'ERROR' }

        _(api_failures.size).must_equal 1
        _(api_failures.first['level']).must_equal 'WARN'
        _(api_failures.first['upstream_status']).must_equal 503
        _(api_failures.first['upstream_response']).must_equal 'Query timed out'
        _(api_failures.first['upstream_path']).must_match %r{\A/landregistry/id/ppd\?}
        _(api_failures.first.key?('status')).must_equal false
        _(errors.size).must_equal 1
        # epilog_rails completes a 5xx request with request_status 'error'
        _(errors.first['request_status']).must_equal 'error'
        _(errors.first['status']).must_equal 503
      end

      it 'should count a failed request and the status the API returned' do
        assert_difference -> { metric(:api_requests, result: 'failure') }, 1 do
          assert_difference -> { metric(:api_service_exception, message: 'HTTP 503') }, 1 do
            VCR.turned_off { get search_index_path(street: 'harbour road') }
          end
        end
      end
    end

    # Only the API rejecting the query we built is a fault in this application
    {
      400 => [:internal_server_error, 1],
      404 => [:bad_gateway, 0],
      503 => [:service_unavailable, 0]
    }.each do |upstream_status, (status, internal_errors)|
      describe "when the API answers #{upstream_status}" do
        before { stub_api_connection { [upstream_status, {}, 'error'] } }

        it "should respond with #{status} and #{internal_errors} internal errors" do
          events = internal_error_events { VCR.turned_off { get search_index_path(street: 'harbour road') } }

          assert_response status
          _(events.size).must_equal internal_errors
        end
      end
    end

    # As on dev on 2026-10-21, when an all-results search was cut off after 120s (#382)
    describe 'when the API answers 200 with a body cut off part way' do
      before { stub_api_connection { [200, { 'Content-Type' => 'application/json' }, '[{"ppd:pricePaid": 2'] } }

      it 'should respond with 502' do
        VCR.turned_off { get search_index_path(street: 'harbour road') }

        assert_response :bad_gateway
      end

      it 'should log that the response could not be read, not that the API returned an error' do
        entries = capture_log { VCR.turned_off { get search_index_path(street: 'harbour road') } }
        api_failures = entries.select { |entry| entry['message'].include?('could not be read (status 200') }

        _(api_failures.size).must_equal 1
        _(api_failures.first['upstream_status']).must_equal 200
        _(api_failures.first['upstream_response']).must_equal '[{"ppd:pricePaid": 2'
        _(entries.none? { |entry| entry['message'].start_with?('API returned status') }).must_equal true
      end
    end

    # Such as a proxy's maintenance page. The gem raises for any body that isn't the
    # JSON it expects, whatever its content type, so ppd never tries to use it.
    describe 'when the API answers 200 with an HTML page' do
      before { stub_api_connection { [200, { 'Content-Type' => 'text/html' }, '<html>Down for maintenance</html>'] } }

      it 'should respond with 502, without counting an internal error' do
        events = internal_error_events { VCR.turned_off { get search_index_path(street: 'harbour road') } }

        assert_response :bad_gateway
        _(events).must_be_empty
      end

      it 'should count a failed API call, not a successful one' do
        assert_no_difference -> { metric(:api_requests, result: 'success') } do
          assert_difference -> { metric(:api_service_exception, message: 'HTTP 200') }, 1 do
            VCR.turned_off { get search_index_path(street: 'harbour road') }
          end
        end
      end

      it 'should log that the response could not be read, with the page it got' do
        entries = capture_log { VCR.turned_off { get search_index_path(street: 'harbour road') } }
        api_failures = entries.select { |entry| entry['message'].include?('could not be read (status 200') }

        _(api_failures.size).must_equal 1
        _(api_failures.first['upstream_response']).must_equal '<html>Down for maintenance</html>'
      end
    end

    describe 'when the API answers 200 with JSON that has no items' do
      before { stub_api_connection { [200, { 'Content-Type' => 'application/json' }, '{"error": "unexpected"}'] } }

      it 'should respond with 502, without counting an internal error' do
        events = internal_error_events { VCR.turned_off { get search_index_path(street: 'harbour road') } }

        assert_response :bad_gateway
        _(events).must_be_empty
      end
    end

    describe 'when the API cannot be reached' do
      before { stub_api_connection { raise Faraday::ConnectionFailed, 'Failed to open TCP connection' } }

      it 'should respond with 503' do
        VCR.turned_off { get search_index_path(street: 'harbour road') }

        assert_response :service_unavailable
      end

      it 'should log the failed call as a warning without a status, since no response arrived' do
        entries = capture_log { VCR.turned_off { get search_index_path(street: 'harbour road') } }
        api_failures = entries.select { |entry| entry['message'].start_with?('Could not connect to the API') }

        _(api_failures.size).must_equal 1
        _(api_failures.first['level']).must_equal 'WARN'
        _(api_failures.first['exception']).must_equal 'Faraday::ConnectionFailed'
        _(api_failures.first.key?('upstream_status')).must_equal false
        _(entries.count { |entry| entry['level'] == 'ERROR' }).must_equal 1
      end

      it 'should count a failed request by exception class' do
        assert_difference -> { metric(:api_requests, result: 'failure') }, 1 do
          assert_difference -> { metric(:api_connection_failure, message: 'Faraday::ConnectionFailed') }, 1 do
            VCR.turned_off { get search_index_path(street: 'harbour road') }
          end
        end
      end
    end
  end
end
