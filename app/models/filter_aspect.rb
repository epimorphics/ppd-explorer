# As aspect class that adds a property value filter
class FilterAspect < Aspect
  def add_clause( query, preferences )
    present?( preferences ) ? add_filter_clause( query, preferences ) : query
  end

  def add_filter_clause( query, preferences )
    if is_uri_value?
      query.eq_any_uri( aspect_property, preference_value( preferences ) )
    else
      query.eq_any_value( aspect_property, preference_value( preferences ), {type: value_type} )
    end
  end

  def operator
    option( :operator )
  end

  def is_uri_value?
    option( :uri_value )
  end

  def value_type
    option( :value_type )
  end

  def search_term( value, preferences )
    SearchTerm.new( key, "#{key} is #{preference_option_label( value )}", value )
  end

  def preference_option_label( value )
    value.gsub( /\A[^\/#:]+./, "" )
         .gsub( /_/, " " )
  end

end
