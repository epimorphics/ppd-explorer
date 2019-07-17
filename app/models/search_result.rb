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

  def initialize(result_json)
    @result = result_json
    ensure_paon_sortable
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

  def value_of_property(prop)
    value_of(@result[prop])
  end

  def presentation_value_of_property(prop)
    v = value_of(@result[prop])

    if no_value?(v)
      nil
    elsif prop == 'ppd:propertyAddressPaon'
      format_paon_elements(v).join(' ').html_safe
    elsif title_case_exception?(prop)
      v
    else
      titlecase_with_hyphens(v)
    end
  end

  def paon
    p = value_of_property('ppd:propertyAddressPaon')
    no_value?(p) ? nil : p
  end

  def paon=(new_paon)
    update_value_for_property(@result, 'ppd:propertyAddressPaon', new_paon)
  end

  def transaction_date
    @transaction_date ||= Date.parse(value_of_property('ppd:transactionDate'))
  end

  def id_of_property(prop)
    id_of(@result[prop])
  end

  def different_key?(other)
    key != other.key
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
    !['false', 'no_value'].include?(nb.to_s)
  end

  def new_build
    { label: "#{new_build? ? '' : 'not '}new-build" }
  end

  def new_build_formatted
    new_build? ? 'yes' : 'no'
  end

  def formatted_address
    fields = []
    formatted_address_saon(fields)
    formatted_address_paon(fields)
    formatted_address_street_town(fields)
    formatted_address_postcode(fields)

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

  def index_key_value(prop)
    v = @result[prop]
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

  def value_of(val)
    return 'no_value' unless val && !empty_string?(val)
    return value_of(val.first) if val.is_a?(Array)
    return value_of(val['@value']) if val.is_a?(Hash)

    val
  end

  def id_of(val)
    return 'no_value' unless val && !empty_string?(val)
    return id_of(val.first) if val.is_a?(Array)
    return id_of(val['@id']) if val.is_a?(Hash)

    val
  end

  def empty_string?(val)
    val.is_a?(String) && val.empty?
  end

  def title_case_exception?(prop)
    prop.to_s == 'ppd:propertyAddressPostcode'
  end

  def titlecase_with_hyphens(str)
    str.split('-').map(&:titlecase).join('-')
  end

  def no_value?(val)
    val.nil? || val == 'no_value'
  end

  def without_leading_segment(term)
    term&.gsub(%r{\A.*/}, '')
  end

  # If there is a PAON value, wrap it in an object wrapper that provides sorting
  # according to HMLR rules
  def ensure_paon_sortable
    return unless (p = paon)

    self.paon = Paon.to_paon(p)
  end

  def formatted_address_saon(fields)
    return unless (saon = presentation_value_of_property('ppd:propertyAddressSaon'))

    fields << "#{saon},"
  end

  def formatted_address_paon(fields)
    return unless (paon = value_of_property('ppd:propertyAddressPaon')) && paon != 'no_value'

    paon_tokens = format_paon_elements(paon)
    comma_not_needed = paon_tokens.last =~ /\d/
    fields << "#{paon_tokens.join(' ')}#{comma_not_needed ? '' : ','}"
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

  def formatted_address_street_town(fields)
    %w[
      ppd:propertyAddressStreet
      ppd:propertyAddressTown
    ].each do |p|
      if (f = presentation_value_of_property(p))
        fields << "#{f},"
      end
    end
  end

  def formatted_address_postcode(fields)
    return unless (postcode = value_of_property('ppd:propertyAddressPostcode'))
    return if postcode == 'no_value'

    fields << postcode
  end
end
