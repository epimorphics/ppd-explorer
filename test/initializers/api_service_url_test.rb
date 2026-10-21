# frozen_string_literal: true

require 'test_helper'

# Unit tests on the boot-time check of API_SERVICE_URL in
# config/initializers/api_service_url.rb
class ApiServiceUrlTest < ActiveSupport::TestCase
  describe 'ApiServiceUrl.validate!' do
    it 'should accept an http URL' do
      assert_nil ApiServiceUrl.validate!('http://localhost:8888')
    end

    it 'should accept an https URL with a path' do
      assert_nil ApiServiceUrl.validate!('https://data-api.example.com/base')
    end

    # The image build boots Rails without it; entrypoint.sh requires it instead
    it 'should skip an unset or empty value' do
      assert_nil ApiServiceUrl.validate!(nil)
      assert_nil ApiServiceUrl.validate!('')
    end

    [
      'localhost:8888',
      'http://local host:8888',
      'htttp://localhost:8888',
      'http://',
      'not a url'
    ].each do |url|
      it "should reject #{url.inspect}, naming the variable" do
        error = assert_raises(ArgumentError) { ApiServiceUrl.validate!(url) }

        assert_includes error.message, 'API_SERVICE_URL'
        assert_includes error.message, url.inspect
      end
    end
  end
end
