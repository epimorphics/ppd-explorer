# Base class to represent an aspect that the user can query for
class Aspect
  attr_reader :aspect_property, :key, :options

  def initialize( key, aspect_property, options = {} )
    @key = key
    @aspect_property = aspect_property
    @options = options
  end

  # Return true if this aspect is present, given the current parameters
  def present?( preferences, value = nil )
    precondition = values ? only_some_present?( values, preferences ) : true
    precondition && preferences.present?( key, value )
  end

  # Return the array of fixed values this aspect, or nil if not defined
  def values
    option( :values )
  end

  # Return an option value
  def option( opt )
    @options[opt]
  end

  # Return the value of this aspect's key from the user preferences
  def preference_value( preferences )
    preferences.param( key )
  end

  # Return a preference value as a number, if possible
  def preference_value_numeric( preferences )
    s = preference_value( preferences )
    Integer( s )
    rescue ArgumentError
      Float( s )
  end

  def key_as_label()
    option( :presentation_label ) || key.to_s.gsub( /_/, " " )
  end

  def uri_as_label( value )
    value.gsub( /\A[^\/#:]+./, "" )
         .gsub( /_/, " " )
  end

  # The key property which gives the key value given an observation, may be different from
  # the aspect property. In particular, the key property may denote a property path, such
  # as propertyAddress/postcode
  def aspect_key_property
    option(:aspect_key_property) || aspect_property
  end

  def key_property
    option( :key_property )
  end

  private

  # Return true if at least one, but not all, of this aspect's values are present in the parameters
  def only_some_present?( values, preferences )
    presence = values.map {|value| preferences.present?( key, value )}
    presence.include?( true ) && presence.include?( false )
  end

end
