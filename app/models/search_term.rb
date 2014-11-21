class SearchTerm
  MAX_LABEL_LENGTH = 30

  attr_reader :name, :value, :values

  def initialize( n, l, v, vs = nil )
    @name = n
    @label = l
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
    long_label? ? truncated_label : clean_label
  end

  def long_label?
    clean_label.length > MAX_LABEL_LENGTH
  end

  def truncated_label
    "#{clean_label.slice( 0, MAX_LABEL_LENGTH )}&hellip;'".html_safe
  end

  def clean_label
    @clean_label ||= ProfanityFilter::Base.clean( @label, 'hollow')
  end
end
