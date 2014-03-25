require 'test_helper'

describe "SearchAspect" do
  before do
    @query = DataServicesApi::QueryGenerator.new
    @aspect = SearchAspect.new( :street, "foo:street", key_property: "foo_key:street" )
  end

  it "should not add a clause if no preference matches" do
    prefs = UserPreferences.new( {"town" => "jklm"})
    q = @aspect.add_clause( @query, prefs )

    q.to_json
     .must_match_json_expression( {} )
  end

  it "should add a clause if a preference matches" do
    prefs = UserPreferences.new( {"street" => "jklm"})
    q = @aspect.add_clause( @query, prefs )

    q.to_json
     .must_match_json_expression( {"foo:street" => {"@search" => {"@value" => "jklm","@property" => "foo_key:street"}}} )
  end
end
