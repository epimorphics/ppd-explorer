# frozen_string_literal: true

require 'test_helper'
describe 'Aspect' do
  it 'should be able to be initialized with a params key' do
    aspect = Aspect.new(:foo, 'foo:bar')
    _(aspect.key).must_equal :foo
  end

  it 'should be able to be initialized with an aspect property' do
    aspect = Aspect.new(:foo, 'foo:bar')
    _(aspect.aspect_property).must_equal 'foo:bar'
  end

  it 'should be able to be initialized with some options' do
    aspect = Aspect.new(:foo, 'foo:bar', 'option' => 'opted')
    _(aspect.option('option')).must_equal 'opted'
  end

  it 'should check just the key for presence in the parameters' do
    aspect = Aspect.new(:street, 'foo:bar')
    assert aspect.present?(UserPreferences.new(params_object('street' => 'bar')))
    assert_not aspect.present?(UserPreferences.new(params_object('town' => 'bar')))
  end

  it 'should not be present if all values are given' do
    aspect = Aspect.new(:street, 'foo:bar', values: %w[a b c])
    assert_not aspect.present?(UserPreferences.new(params_object('street' => %w[a b c])))
  end

  it 'should return a preference value' do
    aspect = Aspect.new(:street, 'foo:bar')
    _(aspect.preference_value(UserPreferences.new(params_object('street' => 'bar')))).must_equal 'bar'
  end

  it 'should parse a preference value as an integer' do
    aspect = Aspect.new(:min_price, '')
    _(aspect.preference_value_numeric(UserPreferences.new(params_object('min_price' => '10'))))
      .must_equal 10
  end

  it 'should parse a preference value as a float' do
    aspect = Aspect.new(:min_price, '')
    _(aspect.preference_value_numeric(UserPreferences.new(params_object('min_price' => '10.1'))))
      .must_be_within_epsilon 10.1
  end

  describe 'a price' do
    def price(value)
      Aspect.new(:min_price, '').preference_value_numeric(UserPreferences.new(params_object('min_price' => value)))
    end

    it 'should accept zero, thousands separators and large numbers' do
      _(price('0')).must_equal 0
      _(price('250,000')).must_equal 250_000
      _(price('99999999999999999999')).must_equal 99_999_999_999_999_999_999
      _(price('1e20')).must_equal 1e20
    end

    it 'should reject a number too large to send, naming it' do
      %w[1e400 -1e400].each do |value|
        error = _ { price(value) }.must_raise MalformedSearchError
        _(error.message).must_equal "'#{value}' is not a valid number"
      end
    end

    it 'should reject a negative price, naming it' do
      error = _ { price('-5') }.must_raise MalformedSearchError
      _(error.message).must_equal "'-5' is not a valid price: it must be zero or more"
    end

    it 'should reject something that is not a number' do
      _ { price('lots') }.must_raise MalformedSearchError
    end
  end

  describe 'a date' do
    include ActiveSupport::Testing::TimeHelpers

    before { travel_to Date.new(2026, 11, 9) }

    def date(value)
      Aspect.new(:min_date, '').preference_value_date(UserPreferences.new(params_object('min_date' => value)))
    end

    it 'should accept dates from 1995 to the end of next year' do
      _(date('1995-01-01')).must_equal Date.new(1995, 1, 1)
      _(date('2026-11-09')).must_equal Date.new(2026, 11, 9)
      _(date('2027-12-31')).must_equal Date.new(2027, 12, 31)
    end

    it 'should reject a date outside the data, naming it and the range' do
      %w[1994-12-31 2028-01-01 99999-01-01 0000-01-01 -0044-03-15].each do |value|
        error = _ { date(value) }.must_raise MalformedSearchError
        _(error.message).must_equal "'#{value}' is not a date between 1 January 1995 and 31 December 2027"
      end
    end

    it 'should reject something that is not a date' do
      error = _ { date('not-a-date') }.must_raise MalformedSearchError
      _(error.message).must_equal "'not-a-date' is not a valid date"
    end
  end
end
