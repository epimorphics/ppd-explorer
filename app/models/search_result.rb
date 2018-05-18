# frozen_string_literal: true

# An individual result returned from the search service
class SearchResult
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

  def initialize(resultJson)
    @result = resultJson

    if p = paon
      paon = Paon.to_paon(p)
    end
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

  def <=>(sr)
    transaction_date <=> sr.transaction_date
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
    puts 'Warning; old buggy paon() method being called'
    p = value_of_property('ppd:propertyAddressPaon')
    is_no_value?(p) ? nil : p
  end

  def paon=(new_paon)
    update_value_for_property(@result, 'ppd:propertyAddressPaon', new_paon)
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

  def is_new_build
    new_build? ? 'yes' : 'no'
  end

  def formatted_address
    fields = []

    if saon = presentation_value_of_property('ppd:propertyAddressSaon')
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
      if f = presentation_value_of_property(p)
        fields << "#{f},"
      end
    end

    if (postcode = value_of_property('ppd:propertyAddressPostcode')) && postcode != 'no_value'
      fields << postcode
    end

    fields.join(' ').html_safe
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

  def update_value_for_property(obj, prop, value)
    target = obj.key?(prop) && obj[prop]

    if target&.is_a?(Array)
      update_value_array(target, value)
    elsif target&.is_a?(Hash)
      target['@value'] = value
    else
      obj[prop] = value
    end
  end

  def update_value_array(target, value)
    if target[0].is_a?(Hash)
      target[0]['@value'] = value
    else
      target[0] = value
    end
  end

  def value_of(v)
    if v.is_a?(Array)
      v = v.empty? ? 'no_value' : v.first
    end

    v = (v['@value'] || v['@value'] || 'no_value') if v.is_a?(Hash)
    empty_string?(v) ? 'no_value' : v
  end

  def id_of(v)
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

  def is_no_value?(v)
    v.nil? || v == 'no_value'
  end

  def without_leading_segment(term)
    term && term.gsub(/\A.*\//, '')
  end
end
