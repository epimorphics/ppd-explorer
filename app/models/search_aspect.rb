# An aspect class that adds a search query term
class SearchAspect < Aspect
  def add_clause( query, preferences )
    add_search_clause( query, preferences ) if present?( preferences )
  end

  def add_search_clause( query, preferences )
    query.search_aspect_property( aspect_property, key_property, preference_value( preferences ))
  end

  def key_property
    option( :key_property )
  end
end
