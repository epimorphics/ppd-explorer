# frozen_string_literal: true

require 'test_helper'
require 'sentry/test_helper'

# Error pages are reached only through `config.exceptions_app`, so these tests
# cause real errors and assert on the response a user would get: the status as
# well as the body.
#
# Every test asserts the correct behaviour. A skipped test is a confirmed defect:
# the skip message records what happens today and the issue that fixes it, and
# that fix should delete the `skip`.
class ErrorHandlingTest < ActionDispatch::IntegrationTest
  include Sentry::TestHelper

  describe 'Error handling' do
    # The test environment raises exceptions (`show_exceptions = :none`). These
    # tests need the exceptions middleware on, and detailed exceptions off:
    # `consider_all_requests_local` is true in test, so otherwise Rails renders
    # its own debug page and never reaches ErrorsController.
    before { @original_env = render_error_pages }
    after { Rails.application.env_config.merge!(@original_env) }

    # Make every call to the Data Services API fail to connect
    def stub_upstream_connection_failure
      dataset = stub('dataset')
      dataset.stubs(:query).raises(Faraday::ConnectionFailed, 'Failed to open TCP connection')
      QueryCommand.any_instance.stubs(:dataset).returns(dataset)
    end

    # Make a search raise an exception nothing in the application expects
    def stub_unhandled_exception
      QueryCommand.any_instance.stubs(:load_query_results).raises(RuntimeError, 'boom')
    end

    def internal_error_count(label)
      Prometheus::Client.registry
                        .get(:internal_application_error)
                        .get(labels: { message: label })
    end

    # The payloads of the internal error events emitted while the block runs
    def internal_error_events(&)
      events = []
      callback = ->(*, payload) { events << payload }
      ActiveSupport::Notifications.subscribed(callback, 'internal_error.application', &)
      events
    end

    describe 'an unmatched path' do
      it 'should respond with 404 and the not found page' do
        get '/no/such/path'

        assert_response :not_found
        assert_includes response.body, 'Page not found'
      end

      it 'should respond with 404 as plain text for a non-HTML format' do
        get '/no/such/path.csv'

        assert_response :not_found
        assert_equal 'Not Found', response.body
      end

      it 'should not serve the error pages at their own paths' do
        get '/500'

        assert_response :not_found
      end

      it 'should not count a client error as an internal error' do
        events = internal_error_events { get '/no/such/path' }

        assert_empty events
      end
    end

    describe 'an invalid search term' do
      it 'should respond with 400 and say why on the search page' do
        get search_index_path(street: 'and')

        assert_response :bad_request
        assert_includes response.body, 'Request not understood'
        assert_includes response.body, 'is not a permissible search term'
      end

      it 'should respond with 400 as plain text on a data download' do
        get '/ppd_data.csv', params: { street: 'and' }

        assert_response :bad_request
        assert_equal 'Bad Request', response.body
      end

      it 'should escape the reason on the error page' do
        get search_index_path(street: 'and')

        assert_includes response.body, 'Sorry, &#39;and&#39; is not a permissible search term'
      end
    end

    describe 'an invalid date' do
      it 'should respond with 400 and say which value was not a valid date' do
        get search_index_path(street: 'harbour road', min_date: 'not-a-date')

        assert_response :bad_request
        assert_includes response.body, 'Request not understood'
        assert_includes response.body, 'is not a valid date'
      end

      it 'should respond with 400 as plain text on a data download' do
        get '/ppd_data.ttl', params: { street: 'harbour road', min_date: 'not-a-date' }

        assert_response :bad_request
        assert_equal 'Bad Request', response.body
      end
    end

    describe 'an invalid price' do
      it 'should respond with 400 and say which value was not a valid number' do
        get search_index_path(street: 'harbour road', min_price: 'lots')

        assert_response :bad_request
        assert_includes response.body, 'is not a valid number'
      end
    end

    describe 'a malformed query string' do
      it 'should respond with 400 and the error page' do
        # Set directly: the test helper would reject this URL before it reached the app
        get '/', env: { 'QUERY_STRING' => 'street=%%_subscriberKey%%' }

        assert_response :bad_request
        assert_includes response.body, 'Request not understood'
      end
    end

    describe 'an upstream API failure' do
      it 'should respond with a gateway error and an error page on the search page' do
        skip 'Confirmed defect: responds 500 as an unhandled NoMethodError. The failure is ' \
             'logged and ignored, then the missing results are read. Fixed in #360'

        stub_upstream_connection_failure

        get search_index_path(street: 'harbour road')

        assert_includes [502, 503], response.status
        assert_includes response.body, 'Application error'
      end

      it 'should respond with a gateway error when all results are requested' do
        skip 'Confirmed defect: responds 200 with a results page. With no limit nothing reads ' \
             'the missing results, and QueryCommand#success? is always true. Fixed in #360'

        stub_upstream_connection_failure

        get search_index_path(street: 'harbour road', limit: 'all')

        assert_includes [502, 503], response.status
      end

      it 'should respond with a gateway error on a data download' do
        skip "Confirmed defect: responds 500 from NoMethodError (undefined method 'size' for " \
             'nil) after the failure is logged and ignored. Fixed in #360'

        stub_upstream_connection_failure

        get '/ppd_data.csv', params: { street: 'harbour road' }

        assert_includes [502, 503], response.status
      end
    end

    describe 'an unhandled exception' do
      it 'should respond with 500 and the application error page' do
        stub_unhandled_exception

        get search_index_path(street: 'harbour road')

        assert_response :internal_server_error
        assert_includes response.body, 'Application error'
        assert_not_includes response.body, 'boom'
      end

      it 'should respond with 500 as plain text for a non-HTML format' do
        stub_unhandled_exception

        get '/search.csv', params: { street: 'harbour road' }

        assert_response :internal_server_error
        assert_equal 'Internal Server Error', response.body
      end

      it 'should emit an internal error event naming the class and action' do
        stub_unhandled_exception

        events = internal_error_events { get search_index_path(street: 'harbour road') }

        assert_equal [{ exception: { class: 'RuntimeError', action: 'search#index',
                                     message: 'boom', status: 500 } }],
                     events
      end

      it 'should count an internal application error by class and action, not message' do
        stub_unhandled_exception

        assert_difference -> { internal_error_count('Unhandled RuntimeError in search#index') }, 1 do
          get search_index_path(street: 'harbour road')
        end
      end

      it 'should report the exception to Sentry' do
        setup_sentry_test
        stub_unhandled_exception

        get search_index_path(street: 'harbour road')

        reported = sentry_events.map { |event| event.exception.values.first.type }

        assert_equal ['RuntimeError'], reported
      ensure
        teardown_sentry_test
      end

      it 'should not report a malformed search to Sentry' do
        setup_sentry_test

        get search_index_path(street: 'and')

        assert_empty sentry_events
      ensure
        teardown_sentry_test
      end
    end
  end
end
