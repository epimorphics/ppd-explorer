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

    _(q.to_json).must_match_json_expression({})
  end

  it 'should not add a clause if all preference values are selected' do
    prefs = UserPreferences.new(params_object('ptype' => %w[a b c]))
    q = @aspect.add_clause(@query, prefs)

    _(q.to_json).must_match_json_expression({})
  end

  it 'should not add a clause if no preference values are selected' do
    prefs = UserPreferences.new(params_object('ptype' => %w[]))
    q = @aspect.add_clause(@query, prefs)

    _(q.to_json).must_match_json_expression({})
  end

  it 'should add a clause if some values are selected' do
    prefs = UserPreferences.new(params_object('ptype' => %w[a b]))
    q = @aspect.add_clause(@query, prefs)

    _(q.to_json).must_match_json_expression(
      '@and' => [
        {
          'foo:propertyType' => {
            '@oneof' => [{ '@value' => 'a' }, { '@value' => 'b' }]
          }
        }
      ]
    )
  end

  it 'should send only the known values when unknown ones are also given' do
    prefs = UserPreferences.new(params_object('ptype' => %w[a nosuch:thing b :]))
    q = @aspect.add_clause(@query, prefs)

    _(q.to_json).must_match_json_expression(
      '@and' => [
        {
          'foo:propertyType' => {
            '@oneof' => [{ '@value' => 'a' }, { '@value' => 'b' }]
          }
        }
      ]
    )
  end

  it 'should not add a clause if only unknown values are given' do
    prefs = UserPreferences.new(params_object('ptype' => %w[nosuch:thing detached]))
    q = @aspect.add_clause(@query, prefs)

    _(q.to_json).must_match_json_expression({})
  end

  # As QueryCommand::ASPECTS defines them, so the prefixes are as the form sends them
  describe 'the search form filters' do
    def clause_for(key, values)
      prefs = UserPreferences.new(params_object(key.to_s => values))
      JSON.parse(QueryCommand.find_aspect(key).add_clause(@query, prefs).to_json)
    end

    it 'should drop a property type with no prefix' do
      _(clause_for(:ptype, %w[lrcommon:detached detached])).must_equal(
        '@and' => [{ 'ppd:propertyType' => { '@oneof' => [{ '@id' => 'lrcommon:detached' }] } }]
      )
    end

    it 'should drop a new build value that is not true or false' do
      _(clause_for(:nb, %w[true maybe])).must_equal(
        '@and' => [{ 'ppd:newBuild' => { '@oneof' => [{ '@value' => 'true', '@type' => 'xsd:boolean' }] } }]
      )
    end
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
    _(term.label).must_match 'estate type is freehold'
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
    _(term.label).must_match 'new build only'
  end
end
