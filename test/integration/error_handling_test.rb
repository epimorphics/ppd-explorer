# frozen_string_literal: true

require 'test_helper'

# Integration tests that cause real errors and assert on the response a user
# would get: the status as well as the body.
#
# Every test asserts the correct behaviour. A skipped test is a confirmed defect:
# the skip message records what happens today and the issue that fixes it, and
# that fix should delete the `skip`.
class ErrorHandlingTest < ActionDispatch::IntegrationTest
  describe 'Error handling' do
    # The test environment raises exceptions (`show_exceptions = :none`). Here we
    # want what production does with an exception that escapes a controller: a
    # response, without the developer's debug page.
    before do
      env = Rails.application.env_config
      @original_env = env.slice('action_dispatch.show_exceptions',
                                'action_dispatch.show_detailed_exceptions')
      env['action_dispatch.show_exceptions'] = :all
      env['action_dispatch.show_detailed_exceptions'] = false
    end

    after do
      Rails.application.env_config.merge!(@original_env)
    end

    # Make every call to the Data Services API fail to connect
    def stub_upstream_connection_failure
      dataset = stub('dataset')
      dataset.stubs(:query).raises(Faraday::ConnectionFailed, 'Failed to open TCP connection')
      QueryCommand.any_instance.stubs(:dataset).returns(dataset)
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
    end

    describe 'an invalid search term' do
      it 'should respond with 400 and say why on the search page' do
        get search_index_path(street: 'and')

        assert_response :bad_request
        assert_includes response.body, 'is not a permissible search term'
      end

      it 'should respond with 400 on a data download' do
        skip 'Confirmed defect: responds 500. `render nothing: true` renders ppd_data/show, ' \
             'which raises NoMethodError on a nil query command. Fixed in #358'

        get '/ppd_data.csv', params: { street: 'and' }

        assert_response :bad_request
      end
    end

    describe 'an invalid date' do
      it 'should respond with 400 and the error page on the search page' do
        get search_index_path(street: 'harbour road', min_date: 'not-a-date')

        assert_response :bad_request
        assert_includes response.body, 'We&#39;re sorry'
      end

      it 'should say which value was not a valid date' do
        skip "Confirmed defect: the page only says 'invalid date'. MalformedSearchError is " \
             'thrown, not raised, so its message is lost and the 400 comes from the ' \
             "underlying ArgumentError. Fixed in #358"

        get search_index_path(street: 'harbour road', min_date: 'not-a-date')

        assert_includes response.body, 'is not a valid date'
      end

      it 'should respond with 400 on a data download' do
        skip 'Confirmed defect: responds 500. The thrown MalformedSearchError surfaces as an ' \
             'UncaughtThrowError, which nothing handles. Fixed in #358'

        get '/ppd_data.csv', params: { street: 'harbour road', min_date: 'not-a-date' }

        assert_response :bad_request
      end
    end

    describe 'an upstream API failure' do
      it 'should respond with a gateway error and an error page on the search page' do
        skip 'Confirmed defect: responds 500 with an empty body. The failure is logged and ' \
             'ignored, a NoMethodError follows on the missing results, and reporting that ' \
             'raises again (see the unhandled exception test). Fixed in #360'

        stub_upstream_connection_failure

        get search_index_path(street: 'harbour road')

        assert_includes [502, 503], response.status
        assert_includes response.body, 'We&#39;re sorry'
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
      it 'should respond with 500 and count an internal application error' do
        skip 'Confirmed defect: the internal_application_error metric is never incremented. ' \
             'SearchController#render_error_page passes a Hash to instrument_internal_error, ' \
             "which raises NoMethodError (undefined method 'message' for Hash), so the error " \
             'page is not rendered either. Fixed in #358'

        QueryCommand.any_instance.stubs(:load_query_results).raises(RuntimeError, 'boom')
        Prometheus::Client.registry.get(:internal_application_error).expects(:increment)

        get search_index_path(street: 'harbour road')

        assert_response :internal_server_error
      end
    end
  end
end
