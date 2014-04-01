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
    SearchTerm.new( key, "#{key_as_label} is #{uri_as_label( value )}", value, option( :values ) )
  end

  def display_checked?( preferences, value )
    only_some_present?( option( :values ), preferences ) ? preferences.present?( key, value ) : true
  end



end
