require 'test_helper'

describe "RangeAspect" do
  before do
    @query = DataServicesApi::QueryGenerator.new
    @aspect = RangeAspect.new( :min_price, "foo:price", operator: "@ge" )
  end

  it "should not add a clause if no preference matches" do
    prefs = UserPreferences.new( {"max_price" => "1000"})
    q = @aspect.add_clause( @query, prefs )

    q.to_json
     .must_match_json_expression( {} )
  end

  it "should add a clause if a preference matches" do
    prefs = UserPreferences.new( {"min_price" => "1000"})
    q = @aspect.add_clause( @query, prefs )

    q.to_json
     .must_match_json_expression( {"foo:price" => {"@ge" => 1000}} )
  end
end
