# frozen_string_literal: true

# Value object encapsulating a user search term
class SearchTerm
  MAX_LABEL_TERM_LENGTH = 15

  attr_reader :name, :value, :values

  def initialize(n, l, v, vs = nil)
    @name = n
    @label_prompt, @label_term = l.split("matches")
    @value = v
    @values = vs
  end

  def button_value
    "remove-#{name}"
  end

  def form_name
    "#{name}#{@values ? [] : ''}"
  end

  def form_value
    # @values ? @values.join(",") : @value
    @value
  end

  def label
    if @label_term
      "#{@label_prompt} matches #{long_label_term? ? truncated_label_term : clean_label_term}"
        .html_safe
    else
      @label_prompt
    end
  end

  def long_label_term?
    @label_term && @label_term.length > MAX_LABEL_TERM_LENGTH
  end

  def truncated_label_term
    "#{clean_label_term.slice(0, MAX_LABEL_TERM_LENGTH)}&hellip;'".html_safe
  end

  def clean_label_term
    # previously we added a profanity filter here, but it was decided not to keep that feature
    @label_term
  end
end
