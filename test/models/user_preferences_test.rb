require 'test_helper'

describe "UserPreferences" do
  it "should provide access to the query parameters" do
    prefs = UserPreferences.new(params_object("street" => "bar"))
    prefs.param("street").must_equal "bar"
    prefs.param("town").must_be_nil
  end

  it "should santize unrecognised inputs" do
    prefs = UserPreferences.new(params_object("fribble" => "bar"))
    prefs.param("fribble").must_be_nil
  end

  it "should report a parameter as present, or not" do
    prefs = UserPreferences.new(params_object("street" => "bar"))
    assert prefs.present?(:street)
    assert !prefs.present?(:town)
  end

  it "should report a parameter as present with a given value, or not" do
    prefs = UserPreferences.new(params_object("street" => "bar"))
    assert prefs.present?(:street, "bar")
    assert !prefs.present?(:street, "blam")
  end

  it "should report a parameter as present, with a list of values, or not" do
    prefs = UserPreferences.new(params_object("nb" => %w(true false)))
    assert prefs.present?(:nb, "true")
    assert prefs.present?(:nb, "false")
    assert !prefs.present?(:nb, "flimflam")
  end
end
