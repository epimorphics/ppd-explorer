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

  # Have the gem talk to a connection that answers every request as the block does
  def stub_api_connection(&)
    stubs = Faraday::Adapter::Test::Stubs.new { |stub| stub.get('/landregistry/id/ppd', &) }
    url = "#{Rails.application.config.api_service_url}/landregistry/id/ppd"
    connection = Faraday.new(url: url) do |config|
      config.response :raise_error
      config.adapter :test, stubs
    end
    DataServicesApi::Service.any_instance.stubs(:create_http_connection).returns(connection)
  end

  def metric(name, labels)
    Prometheus::Client.registry.get(name).get(labels: labels)
  end

  describe 'A failing Data Services API call' do
    before { @original_env = render_error_pages }
    after { Rails.application.env_config.merge!(@original_env) }

    describe 'when the API answers with an error status' do
      before { stub_api_connection { [503, {}, 'Query timed out'] } }

      it 'should respond with 502' do
        VCR.turned_off { get search_index_path(street: 'harbour road') }

        assert_response :bad_gateway
      end

      # The subscriber can't know whether the request will recover, so only the
      # request's completed entry is an ERROR
      it 'should log the failed call once as a warning, and the request once as an error' do
        entries = capture_log { VCR.turned_off { get search_index_path(street: 'harbour road') } }
        api_failures = entries.select { |entry| entry['message'].start_with?('API returned an error') }
        errors = entries.select { |entry| entry['level'] == 'ERROR' }

        _(api_failures.size).must_equal 1
        _(api_failures.first['level']).must_equal 'WARN'
        _(api_failures.first['upstream_status']).must_equal 503
        _(api_failures.first['upstream_path']).must_match %r{\A/landregistry/id/ppd\?}
        _(api_failures.first.key?('status')).must_equal false
        _(errors.size).must_equal 1
        # epilog_rails completes a 5xx request with request_status 'error'
        _(errors.first['request_status']).must_equal 'error'
        _(errors.first['status']).must_equal 502
      end

      it 'should count a failed request and the status the API returned' do
        assert_difference -> { metric(:api_requests, result: 'failure') }, 1 do
          assert_difference -> { metric(:api_service_exception, message: 'HTTP 503') }, 1 do
            VCR.turned_off { get search_index_path(street: 'harbour road') }
          end
        end
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
