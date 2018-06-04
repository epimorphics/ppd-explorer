# frozen_string_literal: true

# As aspect class that adds a property value filter
class FilterAspect < Aspect
  def add_clause(query, preferences)
    present?(preferences) ? add_filter_clause(query, preferences) : query
  end

  def add_filter_clause(query, preferences)
    if is_uri_value?
      query.eq_any_uri(aspect_property, preference_value(preferences))
    else
      query.eq_any_value(aspect_property, preference_value(preferences), type: value_type)
    end
  end

  def operator
    option(:operator)
  end

  def is_uri_value? # rubocop:disable Metrics/PredicateName
    option(:uri_value)
  end

  def value_type
    option(:value_type)
  end

  def search_term(value, _preferences)
    SearchTerm.new(key, filter_value_label(value), value, option(:values))
  end

  def display_checked?(preferences, value)
    only_some_present?(option(:values), preferences) ? preferences.present?(key, value) : true
  end

  private

  def filter_value_label(value)
    if option(:value_labels)
      select_filter_value_label(value)
    else
      generate_filter_value_label(value)
    end
  end

  def generate_filter_value_label(value)
    value_label = is_uri_value? ? uri_as_label(value) : value.to_s
    "#{key_as_label} is #{value_label}"
  end

  def select_filter_value_label(value)
    option(:value_labels)[value.to_s]
  end
end
