# frozen_string_literal: true

require 'test_helper'

# Unit tests on classifying an error response from the Data Services API by who
# has to act on it
class ApiErrorTest < ActiveSupport::TestCase
  def service_exception(status)
    DataServicesApi::ServiceException.new("the server responded with status #{status}", status)
  end

  describe 'ApiError.for' do
    {
      400 => ApiQueryRejectedError,
      422 => ApiQueryRejectedError,
      500 => ApiUnavailableError,
      503 => ApiUnavailableError,
      404 => ApiBadResponseError,
      405 => ApiBadResponseError,
      429 => ApiBadResponseError,
      nil => ApiBadResponseError
    }.each do |status, error_class|
      it "should classify a #{status.inspect} response as #{error_class}" do
        _(ApiError.for(service_exception(status))).must_be_instance_of error_class
      end
    end

    it 'should keep the message' do
      _(ApiError.for(service_exception(503)).message).must_equal 'the server responded with status 503'
    end
  end

  describe 'DataService#call_api' do
    it 'should re-raise an error response, keeping the original as the cause' do
      original = service_exception(400)

      error = assert_raises(ApiQueryRejectedError) do
        DataService.new(nil).call_api { raise original }
      end

      _(error.cause).must_be_same_as original
    end

    it 'should let other exceptions through' do
      assert_raises(Faraday::ConnectionFailed) do
        DataService.new(nil).call_api { raise Faraday::ConnectionFailed, 'refused' }
      end
    end

    it 'should return the result of the call' do
      _(DataService.new(nil).call_api { :result }).must_equal :result
    end
  end
end
