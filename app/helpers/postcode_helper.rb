# frozen_string_literal: true

# Helper for formatting UK postcodes
# Follows standard UK postcode formatting rules, specifically from the
# Ideal Postcodes guide:
# https://ideal-postcodes.co.uk/guides/uk-postcode-format
# and other Royal Mail guidelines.
#
# Formats a UK postcode by ensuring a space is present between
# the outward and inward codes.
#
# Only formats postcodes that are 5-7 characters long without a space,
# as these are unambiguously full postcodes. Shorter strings like "L18"
# are too ambiguous (could be outward code "L18" or sector "L1 8").
#
# @param postcode [String] the postcode to format
# @return [String] the formatted postcode, or original if invalid/ambiguous
module PostcodeHelper
  # Minimum length for a full postcode without space (e.g., "L18JQ" = 5)
  MIN_FULL_POSTCODE_LENGTH = 5
  # Maximum length for a full postcode without space (e.g., "SW1W0NY" = 7)
  MAX_FULL_POSTCODE_LENGTH = 7
  # Inward code is always 3 characters (e.g., "8JQ")
  INWARD_CODE_LENGTH = 3

  # @examples:
  #   format_postcode("AA9A9AA") => "AA9A 9AA"
  #   format_postcode("SW1W0NY") => "SW1W 0NY"
  #   format_postcode("L18JQ")   => "L1 8JQ"
  #   format_postcode("L1 8JQ")  => "L1 8JQ" (already formatted)
  #   format_postcode("L18")     => "L18" (ambiguous, unchanged)
  def format_postcode(postcode)
    return nil if postcode.nil?

    cleaned = postcode.strip.upcase
    return '' if cleaned.empty?
    return cleaned if cleaned.include?(' ')

    insert_space(cleaned)
  end

  private

  def insert_space(postcode)
    unless postcode.length.between?(MIN_FULL_POSTCODE_LENGTH, MAX_FULL_POSTCODE_LENGTH)
      return postcode
    end

    postcode.dup.insert(-INWARD_CODE_LENGTH - 1, ' ')
  end
end
