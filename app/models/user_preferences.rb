# Model to encapsulate user's search preferences
class UserPreferences

  WHITE_LIST = QueryCommand::ASPECTS.keys.map( &:to_s )

  def initialize( p )
    @params = indifferent_access( p )
    sanitise!
  end

  def param( p )
    val = @params[p]
    (val == "") ? nil : val
  end

  # Return truthy if parameter p is present, optionally with value v
  def present?( p, v = nil )
    if v
      param_value = param( p )
      param_value.is_a?( Array ) ? param_value.include?( v ) : (param_value == v)
    else
      param( p )
    end
  end

  private

  def whitelist_params
    WHITE_LIST
  end

  def whitelisted?( param )
    whitelist_params.include?( param.to_s )
  end

  # Remove any non-whitelisted parameters
  def sanitise!
    @params.keep_if {|k,v| whitelisted? k}
  end




  def indifferent_access( h )
    h.is_a?( HashWithIndifferentAccess) ? h : HashWithIndifferentAccess.new( h )
  end

end
