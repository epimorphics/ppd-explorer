# frozen_string_literal: true

require 'test_helper'

describe 'UserPreferences' do
  it 'should provide access to the query parameters' do
    prefs = UserPreferences.new(params_object('street' => 'bar'))
    _(prefs.param('street')).must_equal 'bar'
    _(prefs.param('town')).must_be_nil
  end

  it 'should santize unrecognised inputs' do
    prefs = UserPreferences.new(params_object('fribble' => 'bar'))
    _(prefs.param('fribble')).must_be_nil
  end

  it 'should report a parameter as present, or not' do
    prefs = UserPreferences.new(params_object('street' => 'bar'))
    assert prefs.present?(:street)
    assert_not prefs.present?(:town)
  end

  it 'should report a parameter as present with a given value, or not' do
    prefs = UserPreferences.new(params_object('street' => 'bar'))
    assert prefs.present?(:street, 'bar')
    assert_not prefs.present?(:street, 'blam')
  end

  it 'should report a parameter as present, with a list of values, or not' do
    prefs = UserPreferences.new(params_object('nb' => %w[true false]))
    assert prefs.present?(:nb, 'true')
    assert prefs.present?(:nb, 'false')
    assert_not prefs.present?(:nb, 'flimflam')
  end

  it 'should keep a limit that the form offers' do
    %w[100 1000 all].each do |limit|
      _(UserPreferences.new(params_object('limit' => limit)).selected_limit).must_equal limit
    end
  end

  it 'should use the default limit for one the form does not offer' do
    %w[abc -1 0 50].each do |limit|
      _(UserPreferences.new(params_object('limit' => limit)).selected_limit).must_equal '100'
    end
    _(UserPreferences.new(params_object({})).selected_limit).must_equal '100'
  end
end
