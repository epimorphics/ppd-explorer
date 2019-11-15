# frozen_string_literal: true

require 'test_helper'

describe 'RangeAspect' do
  before do
    @query = DataServicesApi::QueryGenerator.new
    @aspect = RangeAspect.new(:min_price, 'foo:price', operator: '@ge', value_type: :numeric)
  end

  it 'should not add a clause if no preference matches' do
    prefs = UserPreferences.new(params_object('max_price' => '1000'))
    q = @aspect.add_clause(@query, prefs)

    _(q.to_json).must_match_json_expression({})
  end

  it 'should add a clause if a preference matches' do
    prefs = UserPreferences.new(params_object('min_price' => '1000'))
    q = @aspect.add_clause(@query, prefs)

    _(q.to_json)
      .must_match_json_expression('@and' => [{ 'foo:price' => { '@ge' => 1000 } }])
  end
end
