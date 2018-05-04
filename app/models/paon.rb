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

  def self.to_paon(s)
    s.is_a?(Paon) ? s : Paon.new(s.to_s)
  end

  # private

  def elements(paon)
    components = paon.match?(/\A *(\d+[A-Z]*) *\- *(\d+[A-Z]*) *\Z/) ? paon.split('-') : [paon]
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

  def simple_text?(pe)
    not_range?(pe) && name?(pe) && !number?(pe)
  end

  def numeric_following_text?(pe)
    not_range?(pe) && name?(pe) && number?(pe) && !alpha?(pe)
  end

  def not_range?(pe)
    pe.size == 1
  end

  def range?(pe)
    pe.size == 2
  end

  def simple_numeric?(pe)
    not_range?(pe) && !name?(pe) && number?(pe) && !alpha?(pe)
  end

  def numeric_with_alpha?(pe)
    not_range?(pe) && !name?(pe) && number?(pe) && alpha?(pe)
  end

  def numeric_range_no_alpha?(pe)
    range?(pe) && !alpha?(pe, 0) && !alpha?(pe, 1)
  end

  def compare_names(pe0, pe1)
    compare_values(:name, pe0, pe1)
  end

  def compare_numbers(pe0, pe1, i = 0)
    compare_values(:number, pe0, pe1, i)
  end

  def compare_alphas(pe0, pe1)
    compare_values(:alpha, pe0, pe1)
  end

  def compare_values(v, pe0, pe1, i = 0)
    pe0[i][v] <=> pe1[i][v]
  end

  def same_name?(pe0, pe1, i = 0)
    pe0[i][:name] == pe1[i][:name]
  end

  def same_number?(pe0, pe1, i = 0)
    pe0[i][:number] == pe1[i][:number]
  end

  def name?(pe, i = 0)
    pe[i][:name]
  end

  def number?(pe, i = 0)
    number(pe, i)
  end

  def number(pe, i = 0)
    pe[i][:number]
  end

  def alpha?(pe, i = 0)
    pe[i][:alpha]
  end
end
