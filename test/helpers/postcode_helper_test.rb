# frozen_string_literal: true

require 'test_helper'
# nodoc:
class PostcodeHelperTest < ActionView::TestCase
  include PostcodeHelper

  # Full postcodes without space (5-7 chars) should be formatted
  def test_formats_7_char_postcode_without_space
    assert_equal 'AA9A 9AA', format_postcode('AA9A9AA')
  end

  def test_formats_7_char_london_postcode_without_space
    assert_equal 'SW1W 0NY', format_postcode('SW1W0NY')
  end

  def test_formats_6_char_postcode_without_space
    assert_equal 'RH10 8JQ', format_postcode('RH108JQ')
  end

  def test_formats_5_char_postcode_without_space
    assert_equal 'L1 8JQ', format_postcode('L18JQ')
  end

  # Postcodes with space should be normalised but otherwise unchanged
  def test_preserves_correctly_formatted_postcode
    assert_equal 'L1 8JQ', format_postcode('L1 8JQ')
  end

  def test_normalises_lowercase_postcode_with_space
    assert_equal 'SW1W 0NY', format_postcode('sw1w 0ny')
  end

  def test_strips_whitespace_from_postcode_with_space
    assert_equal 'L1 8JQ', format_postcode('  L1 8JQ  ')
  end

  # Ambiguous/partial postcodes (< 5 chars) should not be formatted
  def test_does_not_format_3_char_ambiguous_string
    # L18 could be outward code "L18" (Liverpool 18) or sector "L1 8"
    assert_equal 'L18', format_postcode('L18')
  end

  def test_does_not_format_4_char_outward_code
    assert_equal 'SW1W', format_postcode('SW1W')
  end

  def test_does_not_format_2_char_outward_code
    assert_equal 'L1', format_postcode('L1')
  end

  # Edge cases
  def test_handles_nil_postcode
    assert_nil format_postcode(nil)
  end

  def test_handles_empty_string
    assert_equal '', format_postcode('')
  end

  def test_handles_whitespace_only
    assert_equal '', format_postcode('   ')
  end

  def test_uppercase_normalisation_without_space
    assert_equal 'AA9A 9AA', format_postcode('aa9a9aa')
  end
end
