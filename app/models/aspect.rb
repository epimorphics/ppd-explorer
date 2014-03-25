# Base class to represent an aspect that the user can query for
class Aspect
  attr_reader :aspect_property, :key, :options

  def initialize( key, aspect_property, options = {} )
    @key = key
    @aspect_property = aspect_property
    @options = options
  end

  # Return true if this aspect is present, given the current parameters
  def present?( preferences )
    (values && !all_present( preferences )) || preferences.present?( key )
  end

  # Return the array of fixed values this aspect, or nil if not defined
  def values
    nil
  end

  # Return an option value
  def option( opt )
    @options[opt]
  end

  # Return the value of this aspect's key from the user preferences
  def preference_value( preferences )
    preferences.param( key )
  end

  private

  # Return true if all of this aspect's values are present in the parameters
  def all_present?( preferences )
    values.map {|v| preferences.present?( key, value )}
          .reduce( true ) {|acc, p| p && acc}
  end

end
