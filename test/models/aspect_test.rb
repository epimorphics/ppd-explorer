require 'test_helper'

describe "Aspect" do
  it "should be able to be initialized with a params key" do
    aspect = Aspect.new( :foo, "foo:bar" )
    aspect.key.must_equal :foo
  end

  it "should be able to be initialized with an aspect property" do
    aspect = Aspect.new( :foo, "foo:bar" )
    aspect.aspect_property.must_equal "foo:bar"
  end

  it "should be able to be initialized with some options" do
    aspect = Aspect.new( :foo, "foo:bar", "option" => "opted" )
    aspect.option( "option" ).must_equal "opted"
  end

  it "should check just the key for presence in the parameters" do
    aspect = Aspect.new( :street, "foo:bar" )
    assert( aspect.present?( UserPreferences.new( {"street" => "bar"} )) )
    assert( !aspect.present?( UserPreferences.new( {"town" => "bar"} )) )
  end

  it "should return a preference value" do
    aspect = Aspect.new( :street, "foo:bar" )
    aspect.preference_value( UserPreferences.new( {"street" => "bar"} )).must_equal "bar"
  end

end
