# frozen_string_literal: true

require 'test_helper'

# Search parameters that the form can't produce, as crawlers and scanners send
# them (#385). Each is followed through the real data_services_api gem, with only
# the HTTP connection replaced, to check what would reach the API. None may send
# the API an empty, unknown or out-of-range value: either ppd refuses the search
# with a 400 naming the value, or it drops or replaces the value.
class SearchValidationTest < ActionDispatch::IntegrationTest
  POSTCODE = { postcode: 'PL6 5WS' }.freeze

  # Search with the given parameters, returning the query string of each request
  # made to the API
  def search(params)
    queries = []
    body = { meta: {}, items: [] }.to_json
    stub_api_connection do |env|
      queries << Rack::Utils.parse_query(env.url.query)
      [200, { 'Content-Type' => 'application/json' }, body]
    end
    @internal_errors = internal_error_events do
      VCR.turned_off { get search_index_path(POSTCODE.merge(params)) }
    end
    queries
  end

  describe 'A search with a value the form cannot produce' do
    before { @original_env = render_error_pages }
    after { Rails.application.env_config.merge!(@original_env) }

    {
      { min_price: '1e400' } => "'1e400' is not a valid number",
      { max_price: '-1e400' } => "'-1e400' is not a valid number",
      { max_price: '-5' } => "'-5' is not a valid price",
      { min_date: '99999-01-01' } => "'99999-01-01' is not a date between 1 January 1995",
      { min_date: '0000-01-01' } => "'0000-01-01' is not a date between 1 January 1995",
      { max_date: '-0044-03-15' } => "'-0044-03-15' is not a date between 1 January 1995"
    }.each do |params, reason|
      it "should refuse #{params.to_query} with a 400, without calling the API" do
        queries = search(params)

        assert_response :bad_request
        _(response.body).must_include ERB::Util.html_escape(reason)
        _(queries).must_be_empty
        _(@internal_errors).must_be_empty
      end
    end

    {
      { ptype: %w[lrcommon:detached detached] } => { 'propertyType' => 'detached' },
      { ptype: %w[lrcommon:detached :] } => { 'propertyType' => 'detached' },
      { ptype: %w[lrcommon:detached nosuch:thing] } => { 'propertyType' => 'detached' },
      { nb: %w[true maybe] } => { 'newBuild' => 'true' },
      { limit: 'abc' } => { '_limit' => '100' },
      { limit: '-1' } => { '_limit' => '100' },
      { limit: '0' } => { '_limit' => '100' },
      { max_price: '99999999999999999999' } => { 'maxeq-pricePaid' => '99999999999999999999' },
      { min_price: '1e20' } => { 'mineq-pricePaid' => '1.0e+20' }
    }.each do |params, expected|
      it "should search for #{params.to_query} with only values the API can use" do
        queries = search(params)

        assert_response :ok
        _(queries.size).must_equal 1
        _(queries.first.slice(*expected.keys)).must_equal expected
        _(queries.first.values.flatten.none?(&:blank?)).must_equal true
        _(@internal_errors).must_be_empty
      end
    end
  end
end
