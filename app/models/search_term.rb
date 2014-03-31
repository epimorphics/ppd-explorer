class SearchTerm
  attr_reader :name, :label, :value, :values

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
end
