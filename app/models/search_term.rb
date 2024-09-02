# frozen_string_literal: true

# Value object encapsulating a user search term
class SearchTerm
  MAX_LABEL_TERM_LENGTH = 45

  attr_reader :name, :value, :values

  def initialize(name, label, value, values = nil)
    @name = name
    @label_prompt, @label_term = label.split('matches')
    @value = value
    @values = values
  end

  def button_value
    "remove-#{name}"
  end

  def form_name
    "#{name}#{@values ? [] : ''}"
  end

  def form_value
    # @values ? @values.join(",") : @value
    # remove any HTML tags from the value
    Rails::Html::FullSanitizer.new.sanitize(@value)
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
    # remove any HTML tags from the label term
    term = Rails::Html::FullSanitizer.new.sanitize(@label_term)
    # previously we added a profanity filter here, but it was decided not to keep that feature
    term
  end
end
