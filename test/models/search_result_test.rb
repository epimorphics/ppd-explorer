# frozen-string-literal: true

require 'test_helper'

# Unit tests on the SearchResult model, which encapsulates an individual
# search result from the DsAPI
class SearchResultTest < ActiveSupport::TestCase
  let(:search_result_fixture) do
    file_content = file_fixture('search-result.json').read
    JSON.parse(file_content, symbolize_names: false)
  end

  describe '#uri' do
    it 'should return the URI of the result object' do
      search_result = SearchResult.new(search_result_fixture)
      search_result.uri.must_match %r{^http://landregistry.data.gov.uk/data/ppi/}
    end
  end

  describe '#presentation_value_of_property' do
    it 'should describe a missing value correctly' do
      search_result = SearchResult.new(search_result_fixture)
      search_result.presentation_value_of_property('ppd:propertyAddressSaon')
                   .must_be_nil
    end

    it 'should describe a paon correctly' do
      search_result = SearchResult.new(search_result_fixture)
      search_result.presentation_value_of_property('ppd:propertyAddressPaon')
                   .must_equal 'Rowan House, 6'
    end

    it 'should describe a postcode correctly' do
      search_result = SearchResult.new(search_result_fixture)
      search_result.presentation_value_of_property('ppd:propertyAddressPostcode')
                   .must_equal 'BS39 5SF'
    end

    it 'should use Title Case on other fields' do
      search_result = SearchResult.new(search_result_fixture)
      search_result.presentation_value_of_property('ppd:propertyAddressCounty')
                   .must_equal 'Bath And North East Somerset'
    end
  end

  describe 'special treatment for PAONs' do
    it 'should return nil when PAON is missing' do
      json = {}.merge(search_result_fixture)
      json['ppd:propertyAddressPaon'] = []
      search_result = SearchResult.new(json)

      search_result.paon
                   .must_be_nil
    end

    it 'should return the PAON' do
      json = {}.merge(search_result_fixture)
      search_result = SearchResult.new(json)

      search_result.paon
                   .must_equal 'ROWAN HOUSE, 6'
    end

    it 'should allow the PAON to be updated' do
      json = {}.merge(search_result_fixture)
      search_result = SearchResult.new(json)

      search_result.paon = Paon.new('Totally not the PAON')
      search_result.paon
                   .must_equal 'Totally not the PAON'
    end
  end

  describe 'generating an index key' do
    it 'should create an index key based on the properties of the result' do
      json = {}.merge(search_result_fixture)
      search_result = SearchResult.new(json)

      key = search_result.key
      key.must_be_kind_of Array
      refute(key.find { |k| !k.is_a?(String) })
    end

    it 'should generate a hashcode from the key' do
      json = {}.merge(search_result_fixture)
      search_result = SearchResult.new(json)

      search_result.key_hash.must_be_kind_of(Numeric)
    end
  end

  describe 'transaction date' do
    it 'should parse the transaction date' do
      SearchResult.new(search_result_fixture)
                  .transaction_date
                  .must_equal(Date.new(2006, 9, 28))
    end
  end
end
