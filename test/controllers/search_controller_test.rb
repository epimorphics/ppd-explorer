# frozen_string_literal: true

require 'test_helper'

# :nodoc:
class SearchControllerTest < ActionDispatch::IntegrationTest
  describe 'SearchController' do
    describe 'create' do
      it 'should redirect to the index page if no test params' do
        get search_index_path
        assert_redirected_to(controller: :ppd, action: :index)
      end

      it 'should conduct a search for a house name' do
        VCR.use_cassette('search_controller_test_house_name', record: :new_episodes) do
          get search_index_path(paon: 'rose cottage', limit: 10)

          query_command = @controller.query_command

          match = query_command
                  .search_results
                  .summarise
                  .match(/Showing (\d+) transactions \(from (\d*) or more matching transactions\) for (\d+) properties/)

          _(query_command.size).must_equal 10

          assert match
          _(match[1].to_i).must_equal 10
          _(match[2].to_i).must_be(:>, 0)
          _(match[3].to_i).must_be(:>, 0)
        end
      end
    end
  end
end
