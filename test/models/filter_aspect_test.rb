# frozen_string_literal: true

require 'test_helper'
describe 'FilterAspect' do
  before do
    @query = DataServicesApi::QueryGenerator.new
    @aspect = FilterAspect.new(:ptype, 'foo:propertyType', values: %w[a b c])
  end

  it 'should not add a clause if no preference matches' do
    prefs = UserPreferences.new(params_object('max_price' => '1000'))
    q = @aspect.add_clause(@query, prefs)

    q.to_json.must_match_json_expression({})
  end

  it 'should not add a clause if all preference values are selected' do
    prefs = UserPreferences.new(params_object('ptype' => %w[a b c]))
    q = @aspect.add_clause(@query, prefs)

    q.to_json
     .must_match_json_expression({})
  end

  it 'should not add a clause if no preference values are selected' do
    prefs = UserPreferences.new(params_object('ptype' => %w[]))
    q = @aspect.add_clause(@query, prefs)

    q.to_json
     .must_match_json_expression({})
  end

  it 'should add a clause if some values are selected' do
    prefs = UserPreferences.new(params_object('ptype' => %w[a b]))
    q = @aspect.add_clause(@query, prefs)

    q.to_json.must_match_json_expression(
      '@and' => [
        {
          'foo:propertyType' => {
            '@oneof' => [{ '@value' => 'a' }, { '@value' => 'b' }]
          }
        }
      ]
    )
  end

  it 'should produce a reasonable label with a URI filter value' do
    aspect = FilterAspect.new(
      'test_aspect_type',
      'test_property',
      values: %w[lrcommon:freehold lrcommon:leasehold],
      uri_value: true,
      presentation_label: 'estate type'
    )

    term = aspect.search_term('lrcommon:freehold', {})
    term.label.must_match 'estate type is freehold'
  end

  it 'should produce a reasonable label with a non-URI filter value' do
    aspect = FilterAspect.new(
      'test_aspect_type',
      'test_property',
      values: %w[true false],
      uri_value: false,
      value_type: 'xsd:boolean',
      presentation_label: 'new build?',
      value_labels: { 'true' => 'new build only', 'false' => 'existing buildings only' }
    )

    term = aspect.search_term('true', {})
    term.label.must_match 'new build only'
  end
end
