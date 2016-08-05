# frozen_string_literal: true
require "byebug"

# An aspect class that adds a search query term
class SearchAspect < Aspect
  DEFAULT_LIMIT = 3000000

  LUCENE_KEYWORDS = %w( and or not to )

  def add_clause( query, preferences )
    present?( preferences ) ? add_search_clause( query, preferences ) : query
  end

  def add_search_clause( query, preferences )
    query.search_aspect_property( aspect_property, key_property, text_index_term( preferences ), {"@limit" => DEFAULT_LIMIT})
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
    terms = sanitise_punctuation( preference_value( preferences ) )
      .split( " " )
      .reject {|token| LUCENE_KEYWORDS.include?( token.downcase )}
      .reject {|token| token.empty?}

    if terms.empty?
      raise MalformedSearchError.new( "Sorry, '#{preference_value( preferences )}' is not a permissible search term" )
    end

    terms
        .join( " AND " )
        .gsub( /\A(.*)\Z/, '( \1 )' )
  end

  :private

  # Remove punctuation characters, but allow single apostrophes to remain
  def sanitise_punctuation( str )
    unless has_single_apostrophe?( str )
      str = str.gsub( /([[:alnum:]])[[:punct:]]([[:alnum:]])/, "\\1\\2" )
               .gsub( /[[:punct:]]/, " " )
    end

    str
  end

  def has_single_apostrophe?( str )
    punctuation_filter = /[[:punct:]]/
    punctuation_chars = str.scan( punctuation_filter ).length
    has_apostrophe = str.match( /([[:alnum:]]')|('[[:alnum:]])/ )
    (punctuation_chars == 1) && has_apostrophe
  end
end
