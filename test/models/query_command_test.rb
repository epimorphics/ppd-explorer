# frozen_string_literal: true

require 'test_helper'

class QueryCommandTest < ActiveSupport::TestCase
  describe 'QueryCommand' do
    describe '#load_query_results' do
      it 'should not carry on after the Data Services API could not be reached' do
        dataset = stub('dataset')
        dataset.stubs(:query).raises(Faraday::ConnectionFailed, 'Failed to open TCP connection')
        preferences = UserPreferences.new(params_object('street' => 'harbour road'))
        query_command = QueryCommand.new(preferences)
        query_command.stubs(:dataset).returns(dataset)

        assert_raises(Faraday::ConnectionFailed) { query_command.load_query_results }
        assert_nil query_command.search_results
      end
    end
  end
end
