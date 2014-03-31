# An aspect class that adds a search query term
class SearchAspect < Aspect
  def add_clause( query, preferences )
    present?( preferences ) ? add_search_clause( query, preferences ) : query
  end

  def add_search_clause( query, preferences )
    unless has_search?( query )
      query.search_aspect_property( aspect_property, key_property, text_index_term( preferences ))
    else
      add_search_regex_clause( query, preferences )
    end
  end

  def add_search_regex_clause( query, preferences )
    query.matches( aspect_key_property, preference_value_as_regex( preferences ), flags: "i" )
  end

  def has_search?( query )
    query.terms.has_key?( aspect_property ) &&
    query.terms[aspect_property].has_key?( "@search" )
  end

  def preference_value_as_regex( preferences )
    ".*#{preference_value( preferences )}.*"
  end

  def search_term( value, preferences )
    val = preference_value(preferences)
    SearchTerm.new( key, "#{key_as_label} matches '#{val}'", val )
  end

  # Sanitise input and convert to Lucene expression
  def text_index_term( preferences )
    preference_value( preferences )
        .split( " " )
        .map {|token| token.gsub( /[[:punct:]]/, "" ) }
        .reject {|token| token.empty?}
        .join( " AND " )
        .gsub( /\A(.*)\Z/, '( \1 )' )
  end
end
