require 'test_helper'

# rubocop:disable Metrics/BlockLength
describe "SearchAspect" do
  before do
    @query = DataServicesApi::QueryGenerator.new
    @aspect = SearchAspect.new(:street, "foo:street", key_property: "foo_key:street")
  end

  it "should not add a clause if no preference matches" do
    prefs = UserPreferences.new(params_object("town" => "jklm"))
    q = @aspect.add_clause(@query, prefs)

    q.to_json.must_match_json_expression({})
  end

  it "should add a clause if a preference matches" do
    prefs = UserPreferences.new(params_object("street" => "jklm"))
    q = @aspect.add_clause(@query, prefs)

    q.to_json.must_match_json_expression(
      "@and" => [
        { "foo:street" => {
          "@search" => {
            "@value" => "( jklm )",
            "@property" => "foo_key:street",
            "@limit" => 3_000_000
          }
        } }
      ]
    )
  end

  it "should not generate a search expression that uses a Lucene keyword" do
    prefs = UserPreferences.new(params_object("street" => "there aNd backagain"))
    q = @aspect.add_clause(@query, prefs)

    q.to_json.must_match_json_expression(
      "@and" => [
        { "foo:street" => {
          "@search" => {
            "@value" => "( there AND backagain )",
            "@property" => "foo_key:street",
            "@limit" => 3_000_000
          }
        } }
      ]
    )
  end

  it "should not generate a search expression that uses a double quote (issue-71)" do
    prefs = UserPreferences.new(params_object("street" => "\""))
    assert_raises(MalformedSearchError) do
      @aspect.add_clause(@query, prefs)
    end
  end

  it "should not tokenise terms when sanitising away punctuation" do
    prefs = UserPreferences.new(params_object("street" => "augustine-s"))
    q = @aspect.add_clause(@query, prefs)

    q.to_json.must_match_json_expression(
      "@and" => [
        { "foo:street" => {
          "@search" => {
            "@value" => "( augustines )",
            "@property" => "foo_key:street",
            "@limit" => 3_000_000
          }
        } }
      ]
    )
  end

  it "should not sanitise away a single quote character" do
    prefs = UserPreferences.new(params_object("street" => "augustine's"))
    q = @aspect.add_clause(@query, prefs)

    q.to_json.must_match_json_expression(
      "@and" => [
        { "foo:street" => {
          "@search" => {
            "@value" => "( augustine's )",
            "@property" => "foo_key:street",
            "@limit" => 3_000_000
          }
        } }
      ]
    )
  end

  it "should sanitise away multiple quote characters" do
    prefs = UserPreferences.new(params_object("street" => "'augustine's"))
    q = @aspect.add_clause(@query, prefs)

    q.to_json.must_match_json_expression(
      "@and" => [
        { "foo:street" => {
          "@search" => {
            "@value" => "( augustines )",
            "@property" => "foo_key:street",
            "@limit" => 3_000_000
          }
        } }
      ]
    )
  end

  it "should sanitise away a standalone single quote character" do
    prefs = UserPreferences.new(params_object("street" => "augustine '"))
    q = @aspect.add_clause(@query, prefs)

    q.to_json.must_match_json_expression(
      "@and" => [
        { "foo:street" => {
          "@search" => {
            "@value" => "( augustine )",
            "@property" => "foo_key:street",
            "@limit" => 3_000_000
          }
        } }
      ]
    )
  end
end
