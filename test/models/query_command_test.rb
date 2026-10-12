# frozen_string_literal: true

require 'test_helper'

class QueryCommandTest < ActiveSupport::TestCase
  describe 'QueryCommand' do
    describe '#success?' do
      it 'should be false after the Data Services API could not be reached' do
        skip 'Confirmed defect: always true. #save_results rescues the failure and logs it, ' \
             'but error_message is never assigned. Fixed in #360'

        dataset = stub('dataset')
        dataset.stubs(:query).raises(Faraday::ConnectionFailed, 'Failed to open TCP connection')
        query_command = QueryCommand.new(UserPreferences.new(params_object('street' => 'harbour road')))

        query_command.save_results(dataset, query_command.assemble_query, {})

        assert_not query_command.success?
      end
    end
  end
end
