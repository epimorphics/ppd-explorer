# frozen_string_literal: true

# LR PAONs, which are strings with a custom sort order
class Paon < String # rubocop:disable Metrics/ClassLength
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def <=>(other)
    pe0 = elements(self)
    pe1 = elements(other)

    # start of rule 1
    if simple_text?(pe0) && simple_text?(pe1)
      compare_names(pe0, pe1)
    elsif simple_text?(pe0)
      -1
    elsif simple_text?(pe1)
      1
    elsif number(pe0) != number(pe1)
      compare_numbers(pe0, pe1)
    # start of rule 2; from here, we know the (first) number element is the same
    elsif numeric_following_text?(pe0) && numeric_following_text?(pe1)
      same_name?(pe0, pe1) ? compare_numbers(pe0, pe1) : compare_names(pe0, pe1)
    elsif numeric_following_text?(pe0)
      -1
    elsif numeric_following_text?(pe1)
      1
    # start of rule 3
    elsif simple_numeric?(pe0) && simple_numeric?(pe1)
      compare_numbers(pe0, pe1)
    elsif simple_numeric?(pe0)
      -1
    elsif simple_numeric?(pe1)
      1
    # start of rule 4
    elsif numeric_with_alpha?(pe0) && numeric_with_alpha?(pe1)
      same_number?(pe0, pe1) ? compare_alphas(pe0, pe1) : compare_numbers(pe0, pe1)
    elsif numeric_with_alpha?(pe0)
      -1
    elsif numeric_with_alpha?(pe1)
      1
    elsif numeric_range_no_alpha?(pe0) && numeric_range_no_alpha?(pe1)
      same_number?(pe0, pe1, 0) ? compare_numbers(pe0, pe1, 1) : compare_numbers(pe0, pe1, 0)
    elsif numeric_range_no_alpha?(pe0)
      -1
    elsif numeric_range_no_alpha?(pe1)
      1
    else
      # TODO: there are other cases we might have to consider about sorting with
      # ranges with alphas, but these are not specified in Simon's email
      # For now, we consider them all equal
      0
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def self.to_paon(value)
    value.is_a?(Paon) ? value : Paon.new(value.to_s)
  end

  # private

  def elements(paon)
    components = paon.match?(/\A *(\d+[A-Z]*) *- *(\d+[A-Z]*) *\Z/) ? paon.split('-') : [paon]
    components.map { |p| parse_paon(p) }
  end

  def parse_paon(paon)
    parsed = {}
    tokens = paon.gsub(/(\d+)/, ' \\1 ').split

    parsed[:alpha] = tokens.pop if tokens.length > 1 && tokens.last =~ /\A[A-Z]\Z/
    parsed[:number] = tokens.pop.to_i if tokens.last.match?(/\d/)
    parsed[:name] = tokens.join(' ') unless tokens.empty?

    parsed
  end

  def simple_text?(paon_elem)
    not_range?(paon_elem) && name?(paon_elem) && !number?(paon_elem)
  end

  def numeric_following_text?(paon_elem)
    not_range?(paon_elem) && name?(paon_elem) && number?(paon_elem) && !alpha?(paon_elem)
  end

  def not_range?(paon_elem)
    paon_elem.size == 1
  end

  def range?(paon_elem)
    paon_elem.size == 2
  end

  def simple_numeric?(paon_elem)
    not_range?(paon_elem) && !name?(paon_elem) && number?(paon_elem) && !alpha?(paon_elem)
  end

  def numeric_with_alpha?(paon_elem)
    not_range?(paon_elem) && !name?(paon_elem) && number?(paon_elem) && alpha?(paon_elem)
  end

  def numeric_range_no_alpha?(paon_elem)
    range?(paon_elem) && !alpha?(paon_elem, 0) && !alpha?(paon_elem, 1)
  end

  def compare_names(paon_elem0, paon_elem1)
    compare_values(:name, paon_elem0, paon_elem1)
  end

  def compare_numbers(paon_elem0, paon_elem1, index = 0)
    compare_values(:number, paon_elem0, paon_elem1, index)
  end

  def compare_alphas(paon_elem0, paon_elem1)
    compare_values(:alpha, paon_elem0, paon_elem1)
  end

  def compare_values(value, paon_elem0, paon_elem1, index = 0)
    paon_elem0[index][value] <=> paon_elem1[index][value]
  end

  def same_name?(paon_elem0, paon_elem1, index = 0)
    paon_elem0[index][:name] == paon_elem1[index][:name]
  end

  def same_number?(paon_elem0, paon_elem1, index = 0)
    paon_elem0[index][:number] == paon_elem1[index][:number]
  end

  def name?(paon_elem, index = 0)
    paon_elem[index][:name]
  end

  def number?(paon_elem, index = 0)
    number(paon_elem, index)
  end

  def number(paon_elem, index = 0)
    paon_elem[index][:number]
  end

  def alpha?(paon_elem, index = 0)
    paon_elem[index][:alpha]
  end
end
