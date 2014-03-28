class SearchTerm
  attr_reader :name, :label, :value

  def initialize( n, l, v )
    @name = n
    @label = l
    @value = v
  end

  def button_value
    "remove-#{name}"
  end
end
