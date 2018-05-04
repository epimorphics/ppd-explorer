# frozen_string_literal: true

require 'test_helper'
describe 'Aspect' do
  it 'should be able to be initialized with a params key' do
    aspect = Aspect.new(:foo, 'foo:bar')
    aspect.key.must_equal :foo
  end

  it 'should be able to be initialized with an aspect property' do
    aspect = Aspect.new(:foo, 'foo:bar')
    aspect.aspect_property.must_equal 'foo:bar'
  end

  it 'should be able to be initialized with some options' do
    aspect = Aspect.new(:foo, 'foo:bar', 'option' => 'opted')
    aspect.option('option').must_equal 'opted'
  end

  it 'should check just the key for presence in the parameters' do
    aspect = Aspect.new(:street, 'foo:bar')
    assert aspect.present?(UserPreferences.new(params_object('street' => 'bar')))
    assert !aspect.present?(UserPreferences.new(params_object('town' => 'bar')))
  end

  it 'should not be present if all values are given' do
    aspect = Aspect.new(:street, 'foo:bar', values: %w[a b c])
    assert !aspect.present?(UserPreferences.new(params_object('street' => %w[a b c])))
  end

  it 'should return a preference value' do
    aspect = Aspect.new(:street, 'foo:bar')
    aspect.preference_value(UserPreferences.new(params_object('street' => 'bar'))).must_equal 'bar'
  end

  it 'should parse a preference value as an integer' do
    aspect = Aspect.new(:min_price, '')
    aspect.preference_value_numeric(UserPreferences.new(params_object('min_price' => '10')))
          .must_equal 10
  end

  it 'should parse a preference value as a float' do
    aspect = Aspect.new(:min_price, '')
    aspect.preference_value_numeric(UserPreferences.new(params_object('min_price' => '10.1')))
          .must_be_within_epsilon 10.1
  end
end
