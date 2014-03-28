# An aspect class that adds a range query
class RangeAspect < Aspect
  def add_clause( query, preferences )
    present?( preferences ) ? add_range_clause( query, preferences ) : query
  end

  def add_range_clause( query, preferences )
    query.op( operator, aspect_property, preference_value_numeric( preferences ))
  end

  def operator
    option( :operator )
  end

  def search_term( key, preferences )
    SearchTerm.new( key, "#{key} todo", "todo" )
  end



end
