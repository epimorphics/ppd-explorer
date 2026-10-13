# frozen_string_literal: true

require 'test_helper'
require 'sentry/test_helper'

# Error pages are reached only through `config.exceptions_app`, so these tests
# cause real errors and assert on the response a user would get: the status as
# well as the body.
class ErrorHandlingTest < ActionDispatch::IntegrationTest
  include Sentry::TestHelper

  describe 'Error handling' do
    # The test environment raises exceptions (`show_exceptions = :none`). These
    # tests need the exceptions middleware on, and detailed exceptions off:
    # `consider_all_requests_local` is true in test, so otherwise Rails renders
    # its own debug page and never reaches ErrorsController.
    before { @original_env = render_error_pages }
    after { Rails.application.env_config.merge!(@original_env) }

    # Make every call to the Data Services API fail with the given exception
    def stub_upstream_failure(exception, call = :query)
      dataset = stub('dataset')
      dataset.stubs(call).raises(exception)
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

    # The classes of the exceptions reported to Sentry. Sentry also records a
    # sample of requests as performance transactions, which are not errors.
    def reported_exceptions
      sentry_events.grep(Sentry::ErrorEvent).map { |event| event.exception.values.first.type }
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

    describe 'a Data Services API failure' do
      # The three ways the API can fail, with the status each is given in
      # `rescue_responses` (config/application.rb)
      failures = {
        'that cannot be reached' =>
          [Faraday::ConnectionFailed.new('Failed to open TCP connection'), 503, 'Service Unavailable'],
        'that does not answer in time' =>
          [Faraday::TimeoutError.new('execution expired'), 504, 'Gateway Timeout'],
        'that answers with an error' =>
          [DataServicesApi::ServiceException.new('the server responded with status 503', 503),
           502, 'Bad Gateway']
      }

      failures.each do |description, (exception, status, status_text)|
        describe description do
          before { stub_upstream_failure(exception) }

          it "should respond with #{status} and advice on narrowing the search" do
            get search_index_path(street: 'harbour road')

            assert_response status
            assert_includes response.body, 'the query you have just run did not complete'
            assert_includes response.body, 'Make the query more selective'
          end

          it "should respond with #{status} when all results are requested" do
            get search_index_path(street: 'harbour road', limit: 'all')

            assert_response status
          end

          it "should respond with #{status} as plain text on a data download" do
            get '/ppd_data.csv', params: { street: 'harbour road' }

            assert_response status
            assert_equal status_text, response.body
          end

          it 'should not count it as an internal application error' do
            events = internal_error_events { get search_index_path(street: 'harbour road') }

            assert_empty events
          end
        end
      end

      it 'should respond with a gateway error when the query cannot be explained' do
        stub_upstream_failure(Faraday::ConnectionFailed.new('Failed to open TCP connection'), :explain)

        get '/ppd_data', params: { street: 'harbour road', explain: true }

        assert_response :service_unavailable
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

        assert_equal ['RuntimeError'], reported_exceptions
      ensure
        teardown_sentry_test
      end

      it 'should not report a malformed search to Sentry' do
        setup_sentry_test

        get search_index_path(street: 'and')

        assert_empty reported_exceptions
      ensure
        teardown_sentry_test
      end
    end
  end
end
