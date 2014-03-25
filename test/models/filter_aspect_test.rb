require 'test_helper'

describe "FilterAspect" do
  before do
    @query = DataServicesApi::QueryGenerator.new
    @aspect = FilterAspect.new( :ptype, "foo:propertyType", values: %w(a b c) )
  end

  it "should not add a clause if no preference matches" do
    prefs = UserPreferences.new( {"max_price" => "1000"})
    q = @aspect.add_clause( @query, prefs )

    q.to_json
     .must_match_json_expression( {} )
  end

  it "should not add a clause if all preference values are selected" do
    prefs = UserPreferences.new( {"ptype" => %w(a b c)})
    q = @aspect.add_clause( @query, prefs )

    q.to_json
     .must_match_json_expression( {} )
  end

  it "should not add a clause if no preference values are selected" do
    prefs = UserPreferences.new( {"ptype" => %w()})
    q = @aspect.add_clause( @query, prefs )

    q.to_json
     .must_match_json_expression( {} )
  end

  it "should add a clause if some values are selected" do
    prefs = UserPreferences.new( {"ptype" => %w(a b)})
    q = @aspect.add_clause( @query, prefs )

    q.to_json
     .must_match_json_expression(
        {"foo:propertyType" => {
          "@or" => [{"@eq" => "a"}, {"@eq" => "b"}]}
        } )
  end
end
