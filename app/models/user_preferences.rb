# Model to encapsulate user's search preferences
class UserPreferences

  WHITE_LIST = QueryCommand::ASPECTS.keys.map( &:to_s )

  def initialize( p )
    @params = indifferent_access( p )
    process_removes
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

  # Yield a block to each search term with a non-empty value
  def each_search_term( &block )
    QueryCommand::ASPECTS.each do |key,aspect|
      yield aspect.search_term( key, self ) if present?( key, @params[key] )
    end
  end

  # Return true if there are no params set
  def empty?
    QueryCommand::ASPECTS.keys.reduce( true ) do |acc, aspect_name|
      acc && !present?( aspect_name, param( aspect_name ) )
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

  def process_removes
    r = param( "remove-search" )
    @params.delete( r ) if r
  end


  def indifferent_access( h )
    h.is_a?( HashWithIndifferentAccess) ? h : HashWithIndifferentAccess.new( h )
  end

end
