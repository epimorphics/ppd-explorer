require "test_helper"

describe "TurtleFormatter" do
  include TurtleFormatter

  it "should recognise the @id property of JSON-LD" do
    result_to_ttl( {"@id" => "http://foo"} ).must_equal( {uri: "<http://foo>", properties: []} )
  end

  it "should omit the URI for an encoded bNode" do
    result_to_ttl( {} ).must_equal( {properties: []} )
  end

  it "should encode a property as turtle" do
    json = {"foo:bar" => 42}
    result_to_ttl( json ).must_equal( {properties: [{p: "foo:bar", v: "42"}]} )
  end

  it "should encode multi-value properties" do
    json = {"foo:bar" => [1,2]}
    result_to_ttl( json ).must_equal( {properties: [{p: "foo:bar", v: "1, 2"}]} )
  end

  it "should omit properties with no value" do
    json = {"foo:bar" => []}
    result_to_ttl( json ).must_equal( {properties: []} )
  end

  it "should encode a nil value" do
    format_ttl_value( nil ).must_equal( "" )
  end

  it "should encode a numeric value" do
    format_ttl_value( 42 ).must_equal( "42" )
  end

  it "should encode an array value" do
    format_ttl_value( [1,2] ).must_equal( "1, 2" )
  end

  it "should recognise an encoded URI" do
    format_ttl_value( "http://foo.bar/bam" ).must_equal( "<http://foo.bar/bam>" )
  end

  it "should recognise a qname" do
    format_ttl_value( "prefix:name_part" ).must_equal( "prefix:name_part" )
  end

  it "should recognise boolean values" do
    format_ttl_value( true ).must_equal( "true" )
    format_ttl_value( false ).must_equal( "false" )
  end

  it "should recognise an encoded URI term" do
    format_ttl_value( {"@id" => "http://fu.bar"} ).must_equal( "<http://fu.bar>" )
  end

  it "should recognise a value with a type" do
    format_ttl_value( {"@value" => 42, "@type" => "xsd:int"} ).must_equal( "\"42\"^^xsd:int" )
  end

  it "should recognise a value with no type" do
    format_ttl_value( {"@value" => 42} ).must_equal( "\"42\"" )
  end

  it "should flag a default encoding fall-through" do
    format_ttl_value( {"@jellybean" => "blueberry"} ).must_match( /default/ )
  end
end
