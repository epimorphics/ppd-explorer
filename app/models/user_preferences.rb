# Model to encapsulate user's search preferences
class UserPreferences
  include Rails.application.routes.url_helpers

  WHITE_LIST = QueryCommand::ASPECTS.keys.map( &:to_s ) + %w(search)

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
        # binding.pry
      param_value = param( p )
      param_value.is_a?( Array ) ? param_value.include?( v ) : (param_value == v)
    else
      param( p )
    end
  end

  # Yield a block to each search term with a non-empty value
  def each_search_term( &block )
    QueryCommand::ASPECTS.each do |key,aspect|
      (aspect.option( :values ) || [nil]).each do |value|
        if aspect.present?( self, value )
          yield aspect.search_term( value, self )
        end
      end
    end
  end

  # Return true if there are no params set
  def empty?
    QueryCommand::ASPECTS.keys.reduce( true ) do |acc, aspect_name|
      acc && !present?( aspect_name, param( aspect_name ) )
    end
  end

  # Return the current preferences as arguments to the given controller path
  def as_path( controller, options = {}, remove = [] )
    path_params = @params.merge( options )
    process_removes( remove )

    path =
      case controller
      when :ppd
        ppd_index_path( path_params )
      when :search
        search_index_path( path_params )

      else
        raise "Do not know how to make path for #{controller}"
      end

    # this shouldn't be necessay if ENV[RAILS_RELATIVE_ROOT] was working correctly
    path.gsub( /^/, "#{ENV['RAILS_RELATIVE_URL_ROOT']}" )
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

  # Process any instructions to remove a value from the params
  def process_removes( removes )
    removes.each do |r,v|
      if @params[r].is_a?( Array )
        @params[r].delete( v )
        @params.delete( r ) if @params[r].empty?
      else
        @params.delete( r )
      end
    end
  end


  def indifferent_access( h )
    h.is_a?( HashWithIndifferentAccess) ? h : HashWithIndifferentAccess.new( h )
  end

end
