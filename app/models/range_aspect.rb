# frozen_string_literal: true

# An aspect class that adds a range query
class RangeAspect < Aspect
  def add_clause(query, preferences)
    present?(preferences) ? add_range_clause(query, preferences) : query
  end

  def add_range_clause(query, preferences)
    query.op(operator, aspect_property, preference_value_as_type(value_type, preferences))
  end

  def operator
    option(:operator)
  end

  def search_term(_value, preferences)
    val = preference_value_as_type(value_type, preferences)
    SearchTerm.new(key, prompt(val), val)
  end

  def value_type
    option(:value_type)
  end

  def prompt(val)
    prompt_string = option(:prompt) || '%s %s'
    format(prompt_string, key_as_label, val).html_safe
  end
end
