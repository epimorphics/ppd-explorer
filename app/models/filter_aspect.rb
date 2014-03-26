# As aspect class that adds a property value filter
class FilterAspect < Aspect
  def add_clause( query, preferences )
    present?( preferences ) ? add_filter_clause( query, preferences ) : query
  end

  def add_filter_clause( query, preferences )
    query.eq_any_uri( aspect_property, preference_value( preferences ))
  end

  def operator
    option( :operator )
  end

end
