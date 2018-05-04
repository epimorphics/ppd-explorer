# frozen_string_literal: true

# An individual result returned from the search service
class SearchResult # rubocop:disable Metrics/ClassLength
  attr_reader :result

  PPD = 'http://landregistry.data.gov.uk/def/ppi/'

  INDEX_KEY_PROPERTIES =
    %w[
      ppd:propertyAddressPostcode
      ppd:propertyAddressCounty
      ppd:propertyAddressDistrict
      ppd:propertyAddressTown
      ppd:propertyAddressStreet
      ppd:propertyAddressPaon
      ppd:propertyAddressSaon
    ].freeze

  DETAILED_ADDRESS_PROPERTIES =
    %w[
      ppd:propertyAddressSaon
      ppd:propertyAddressPaon
      ppd:propertyAddressStreet
      ppd:propertyAddressLocality
      ppd:propertyAddressTown
      ppd:propertyAddressDistrict
      ppd:propertyAddressCounty
      ppd:propertyAddressPostcode
    ].freeze

  DETAILED_ADDRESS_ASPECTS =
    DETAILED_ADDRESS_PROPERTIES.map do |ap|
      QueryCommand::ASPECTS.values.find { |a| a.aspect_key_property == ap }
    end

  GROUP_HEADING_PROPERTIES =
    %w[
      ppd:propertyAddressStreet
      ppd:propertyAddressTown
      ppd:propertyAddressCounty
    ].freeze

  def initialize(result_json)
    @result = result_json
    return unless (p = paon)
    self.paon = Paon.to_paon(p)
  end

  def key
    @key ||= INDEX_KEY_PROPERTIES.map { |p| index_key_value(p) }
  end

  def key_hash
    @key_hash ||= key.map(&:hash).reduce(&:^)
  end

  def uri
    id_of(@result)
  end

  def <=>(other)
    transaction_date <=> other.transaction_date
  end

  def value_of_property(p)
    value_of(@result[p])
  end

  def presentation_value_of_property(p)
    v = value_of(@result[p])

    if is_no_value?(v)
      nil
    elsif p == 'ppd:propertyAddressPaon'
      format_paon_elements(v).join(' ').html_safe
    elsif title_case_exception?(p)
      v
    else
      titlecase_with_hyphens(v)
    end
  end

  def paon
    p = value_of('ppd:propertyAddressPaon')
    is_no_value?(p) ? nil : p
  end

  def paon=(p)
    if @result['ppd:propertyAddressPaon'].is_a?(Array)
      @result['ppd:propertyAddressPaon'][0]['@value'] = p
    else
      @result['ppd:propertyAddressPaon'] = p
    end
  end

  def transaction_date
    @transaction_date ||= Date.parse(value_of_property('ppd:transactionDate'))
  end

  def id_of_property(p)
    id_of(@result[p])
  end

  def different_key?(sr)
    key != sr.key
  end

  def property_details
    [property_type, estate_type, new_build]
  end

  def property_type
    pt = id_of_property('ppd:propertyType')
    { uri: pt, label: property_type_label }
  end

  # TODO: workaround for DsAPI bug - should have access to the @label
  def property_type_label
    pt = id_of_property('ppd:propertyType')
    pt_label = without_leading_segment(pt).underscore.humanize.downcase

    pt_label.gsub(/ property type/, '')
  end

  def estate_type
    et = id_of_property('ppd:estateType')
    { uri: et, label: without_leading_segment(et) }
  end

  def new_build?
    nb = value_of_property('ppd:newBuild')
    !(nb == 'false' || nb == false || nb == 'no_value')
  end

  def new_build
    { label: "#{new_build? ? '' : 'not '}new-build" }
  end

  def new_build_yes_no
    new_build? ? 'yes' : 'no'
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def formatted_address
    fields = []

    if (saon = presentation_value_of_property('ppd:propertyAddressSaon'))
      fields << "#{saon},"
    end

    if (paon = value_of_property('ppd:propertyAddressPaon')) && paon != 'no_value'
      paon_tokens = format_paon_elements(paon)
      comma_not_needed = paon_tokens.last =~ /\d/
      fields << "#{paon_tokens.join(' ')}#{comma_not_needed ? '' : ','}"
    end

    %w[
      ppd:propertyAddressStreet
      ppd:propertyAddressTown
    ].each do |p|
      if (f = presentation_value_of_property(p))
        fields << "#{f},"
      end
    end

    if (postcode = value_of_property('ppd:propertyAddressPostcode')) && postcode != 'no_value'
      fields << postcode
    end

    fields.join(' ').html_safe
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def group_heading(previous)
    gk = group_key
    gk.select { |v| v }.join(', ') if !previous || gk != previous.group_key
  end

  def group_key
    GROUP_HEADING_PROPERTIES.map { |p| value_of_property p }
  end

  def formatted_transaction_category
    case value_of_property('ppd:transactionCategory')
    when "#{PPD}additionalPricePaidTransaction"
      { display: 'B', label: 'Additional price paid transaction' }
    when "#{PPD}standardPricePaidTransaction"
      { display: 'A', label: 'Standard price paid transaction' }
    else
      { display: '', label: '' }
    end
  end

  private

  def index_key_value(p)
    v = @result[p]
    return 'no_value' unless v
    return 'no_value' if empty_string?(v)
    value_of(v)
  end

  def value_of(v) # rubocop:disable Metrics/CyclomaticComplexity
    if v.is_a?(Array)
      v = v.empty? ? 'no_value' : v.first
    end

    v = (v['@value'] || v['@value'] || 'no_value') if v.is_a?(Hash)
    empty_string?(v) ? 'no_value' : v
  end

  def id_of(v) # rubocop:disable Metrics/CyclomaticComplexity
    if v.is_a?(Array)
      v = v.empty? ? 'no_value' : v.first
    end

    v = (v['@id'] || v['@id'] || 'no_value') if v.is_a?(Hash)
    empty_string?(v) ? 'no_value' : v
  end

  def empty_string?(v)
    v.is_a?(String) && v.empty?
  end

  def title_case_exception?(p)
    p.to_s == 'ppd:propertyAddressPostcode'
  end

  def format_paon_elements(paon)
    paon.split(' ').map do |token|
      case token
      when /\d/
        token
      when '-'
        '&ndash;'
      else
        token.titlecase
      end
    end
  end

  def titlecase_with_hyphens(str)
    str.split('-').map(&:titlecase).join('-')
  end

  def is_no_value?(v) # rubocop:disable Metrics/PredicateName
    v.nil? || v == 'no_value'
  end

  def without_leading_segment(term)
    term && term.gsub(%r{\A.*/}, '')
  end
end
