# frozen_string_literal: true

require 'test_helper'
require_relative '../../app/models/search_result'

class SearchResultsTest < ActiveSupport::TestCase
  describe 'SearchResults' do
    PAC = 'ppd:propertyAddressCounty'
    PAL = 'ppd:propertyAddressLocality'
    PAD = 'ppd:propertyAddressDistrict'
    PAT = 'ppd:propertyAddressTown'
    PAS = 'ppd:propertyAddressStreet'
    PAP = 'ppd:propertyAddressPaon'
    PASN = 'ppd:propertyAddressSaon'

    it 'should index a sample result' do
      result = { PAC => { '@value' => 'a-county' },
                 PAL => { '@value' => 'a-locality' },
                 PAD => { '@value' => 'a-district' },
                 PAT => { '@value' => 'a-town' },
                 PAS => { '@value' => 'a-street' },
                 PAP => { '@value' => 'a-paon' },
                 PASN => { '@value' => 'a-saon' },
                 'ppd:pricePaid' => 100 }

      sr = SearchResults.new([result], 100)

      _(sr.index['no_value']).must_be_kind_of Hash
      _(sr.index['no_value']['a-county']).must_be_kind_of Hash
      _(sr.index['no_value']['a-county']).must_be_kind_of Hash
      _(sr.index['no_value']['a-county']['a-district']).must_be_kind_of Hash
      _(sr.index['no_value']['a-county']['a-district']['a-town']).must_be_kind_of Hash
      _(sr.index['no_value']['a-county']['a-district']['a-town']['a-street']).must_be_kind_of Hash
      _(sr.index['no_value']['a-county']['a-district']['a-town']['a-street']['a-paon']).must_be_kind_of Hash
      _(sr.index['no_value']['a-county']['a-district']['a-town']['a-street']['a-paon']['a-saon']).must_be_kind_of Array
      _(sr.index['no_value']['a-county']['a-district']['a-town']['a-street']['a-paon']['a-saon'][0].value_of_property('ppd:pricePaid')).must_equal 100
    end

    it 'should search on locality' do
      result = {
        PAL => { '@value' => 'a-locality' },
        'ppd:pricePaid' => 100
      }
      sr = SearchResults.new([result], 1)

      _(sr.index['no_value']['a-locality']).must_be_kind_of Hash
    end

    it 'should index in the face of missing values' do
      result = { PAC => { '@value' => 'a-county' },
                 PAD => { '@value' => 'a-district' },
                 PAT => { '@value' => 'a-town' },
                 PAS => { '@value' => 'a-street' },
                 PAP => { '@value' => 'a-paon' },
                 PASN => { '@value' => '' },
                 'ppd:pricePaid' => 100 }

      sr = SearchResults.new([result], 100)

      _(sr.index).must_be_kind_of Hash
      _(sr.index['no_value']).must_be_kind_of Hash
      _(sr.index['no_value']['a-county']).must_be_kind_of Hash
      _(sr.index['no_value']['a-county']['a-district']).must_be_kind_of Hash
      _(sr.index['no_value']['a-county']['a-district']['a-town']).must_be_kind_of Hash
      _(sr.index['no_value']['a-county']['a-district']['a-town']['a-street']).must_be_kind_of Hash
      _(sr.index['no_value']['a-county']['a-district']['a-town']['a-street']['a-paon']).must_be_kind_of Hash
      _(sr.index['no_value']['a-county']['a-district']['a-town']['a-street']['a-paon']['no_value']).must_be_kind_of Array
      _(sr.index['no_value']['a-county']['a-district']['a-town']['a-street']['a-paon']['no_value'][0].value_of_property('ppd:pricePaid')).must_equal 100
    end

    it 'should collate results with the same address' do
      result0 = { PAC => { '@value' => 'a-county' },
                  PAD => { '@value' => 'a-district' },
                  PAT => { '@value' => 'a-town' },
                  PAS => { '@value' => 'a-street' },
                  PAP => { '@value' => 'a-paon' },
                  PASN => { '@value' => '' },
                  'ppd:pricePaid' => 100,
                  'ppd:transactionDate' => { '@value' => '2013-01-02' } }

      resultb = { PAC => { '@value' => 'b-county' },
                  PAD => { '@value' => 'a-district' },
                  PAT => { '@value' => 'a-town' },
                  PAS => { '@value' => 'a-street' },
                  PAP => { '@value' => 'a-paon' },
                  PASN => { '@value' => '' },
                  'ppd:pricePaid' => 200 }

      result1 = { PAC => { '@value' => 'a-county' },
                  PAD => { '@value' => 'a-district' },
                  PAT => { '@value' => 'a-town' },
                  PAS => { '@value' => 'a-street' },
                  PAP => { '@value' => 'a-paon' },
                  PASN => { '@value' => '' },
                  'ppd:pricePaid' => 101,
                  'ppd:transactionDate' => { '@value' => '2013-01-01' } }

      sr = SearchResults.new([result0, resultb, result1], 100)
      txs = sr.index['no_value']['a-county']['a-district']['a-town']['a-street']['a-paon']['no_value']
      _(txs.map { |t| t.value_of_property('ppd:pricePaid') }).must_equal [100, 101]
    end

    it 'should traverse in order' do
      result0 = { PAC => { '@value' => 'a-county' },
                  PAL => { '@value' => 'a-locality' },
                  PAD => { '@value' => 'a-district' },
                  PAT => { '@value' => 'a-town' },
                  PAS => { '@value' => 'c-street' },
                  PAP => { '@value' => 'a-paon' },
                  PASN => { '@value' => 'a-saon' },
                  'ppd:pricePaid' => 100,
                  'ppd:transactionDate' => { '@value' => '2013-01-01' } }
      result1 = { PAC => { '@value' => 'a-county' },
                  PAL => { '@value' => 'a-locality' },
                  PAD => { '@value' => 'a-district' },
                  PAT => { '@value' => 'a-town' },
                  PAS => { '@value' => 'd-street' },
                  PAP => { '@value' => 'a-paon' },
                  PASN => { '@value' => 'a-saon' },
                  'ppd:pricePaid' => 101,
                  'ppd:transactionDate' => { '@value' => '2013-01-01' } }
      result2 = { PAC => { '@value' => 'a-county' },
                  PAL => { '@value' => 'a-locality' },
                  PAD => { '@value' => 'a-district' },
                  PAT => { '@value' => 'b-town' },
                  PAS => { '@value' => 'd-street' },
                  PAP => { '@value' => 'a-paon' },
                  PASN => { '@value' => 'a-saon' },
                  'ppd:pricePaid' => 102,
                  'ppd:transactionDate' => { '@value' => '2013-01-01' } }
      result3 = { PAC => { '@value' => 'a-county' },
                  PAL => { '@value' => 'a-locality' },
                  PAD => { '@value' => 'a-district' },
                  PAT => { '@value' => 'b-town' },
                  PAS => { '@value' => 'e-street' },
                  PAP => { '@value' => 'a-paon' },
                  PASN => { '@value' => 'a-saon' },
                  'ppd:pricePaid' => 110,
                  'ppd:transactionDate' => { '@value' => '2014-01-01' } }
      result4 = { PAC => { '@value' => 'a-county' },
                  PAL => { '@value' => 'a-locality' },
                  PAD => { '@value' => 'a-district' },
                  PAT => { '@value' => 'b-town' },
                  PAS => { '@value' => 'e-street' },
                  PAP => { '@value' => 'a-paon' },
                  PASN => { '@value' => 'a-saon' },
                  'ppd:pricePaid' => 109,
                  'ppd:transactionDate' => { '@value' => '2014-01-02' } }
      result5 = { PAC => { '@value' => 'a-county' },
                  PAL => { '@value' => 'a-locality' },
                  PAD => { '@value' => 'a-district' },
                  PAT => { '@value' => 'b-town' },
                  PAS => { '@value' => 'e-street' },
                  PAP => { '@value' => 'a-paon' },
                  PASN => { '@value' => 'a-saon' },
                  'ppd:pricePaid' => 108,
                  'ppd:transactionDate' => { '@value' => '2014-01-03' } }

      sr = SearchResults.new([result0, result1, result2, result3, result4, result5], 100)

      prices = []
      sr.each_transaction { |tx| prices << tx.value_of_property('ppd:pricePaid') }
      _(prices).must_equal [100, 101, 102, 108, 109, 110]
    end

    it 'should count correctly when the limit is hit' do
      result0 = { PAC => { '@value' => 'a-county' },
                  PAD => { '@value' => 'a-district' },
                  PAT => { '@value' => 'a-town' },
                  PAS => { '@value' => 'a-street' },
                  PAP => { '@value' => 'a-paon' },
                  PASN => { '@value' => '' },
                  'ppd:pricePaid' => 100,
                  'ppd:transactionDate' => { '@value' => '2013-01-02' } }

      result1 = { PAC => { '@value' => 'a-county' },
                  PAD => { '@value' => 'a-district' },
                  PAT => { '@value' => 'a-town' },
                  PAS => { '@value' => 'a-street' },
                  PAP => { '@value' => 'b-paon' },
                  PASN => { '@value' => '' },
                  'ppd:pricePaid' => 101,
                  'ppd:transactionDate' => { '@value' => '2013-01-01' } }

      sr = SearchResults.new([result0, result1], 1)
      _(sr.properties).must_equal 2
    end
  end
end
