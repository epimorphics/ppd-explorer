# An individual result returned from the search service
class SearchResult
  attr_reader :result

  INDEX_KEY_PROPERTIES =
      %w(
        ppd:propertyAddressCounty
        ppd:propertyAddressDistrict
        ppd:propertyAddressTown
        ppd:propertyAddressStreet
        ppd:propertyAddressPaon
        ppd:propertyAddressSaon
      )

  DETAILED_ADDRESS_PROPERTIES =
      %w(
        ppd:propertyAddressSaon
        ppd:propertyAddressPaon
        ppd:propertyAddressStreet
        ppd:propertyAddressLocality
        ppd:propertyAddressTown
        ppd:propertyAddressDistrict
        ppd:propertyAddressCounty
        ppd:propertyAddressPostcode
      )

  DETAILED_ADDRESS_ASPECTS =
    DETAILED_ADDRESS_PROPERTIES.map do |ap|
      QueryCommand::ASPECTS.values.find {|a| a.aspect_key_property == ap}
    end

  GROUP_HEADING_PROPERTIES =
    %w(
      ppd:propertyAddressStreet
      ppd:propertyAddressTown
      ppd:propertyAddressCounty
    )

  def initialize( resultJson )
    @result = resultJson
    if p = paon
      paon = Paon.to_paon( p )
    end
  end

  def key
    @key ||= INDEX_KEY_PROPERTIES.map {|p| index_key_value( p )}
  end

  def uri
    id_of( @result )
  end

  def <=>( sr )
    transaction_date <=> sr.transaction_date
  end

  def value_of_property( p )
    value_of( @result[p] )
  end

  def presentation_value_of_property( p )
    v = value_of( @result[p] )

    if is_no_value?( v )
      nil
    elsif p == "ppd:propertyAddressPaon"
      format_paon_elements( v ).join( ' ' ).html_safe
    elsif title_case_exception?( p )
      v
    else
      titlecase_with_hyphens( v )
    end
  end

  def paon
    p = value_of( "ppd:propertyAddressPaon" )
    is_no_value?( p ) ? nil : p
  end

  def paon=( p )
    if @result["ppd:propertyAddressPaon"].kind_of?( Array )
      @result["ppd:propertyAddressPaon"][0]["@value"] = p
    else
      @result["ppd:propertyAddressPaon"] = p
    end
  end

  def transaction_date
    @transaction_date ||= Date.parse( value_of_property( "ppd:transactionDate" ))
  end

  def id_of_property( p )
    id_of( @result[p] )
  end

  def different_key?( sr )
    key != sr.key
  end

  def property_details
    [property_type, estate_type, new_build]
  end

  def property_type
    pt = id_of_property( "ppd:propertyType" )
    {uri: pt, label: pt.gsub( /\A.*\//, "" )}
  end

  def estate_type
    et = id_of_property( "ppd:estateType" )
    {uri: et, label: et.gsub( /\A.*\//, "" )}
  end

  def new_build?
    nb = value_of_property( "ppd:newBuild" )
    return !(nb == "false" || nb == false || nb == "no_value")
  end

  def new_build
    {label: "#{new_build? ? "" : "not "}new-build"}
  end

  def is_new_build
    new_build? ? "yes" : "no"
  end

  def formatted_address
    fields = []

    if saon = presentation_value_of_property( "ppd:propertyAddressSaon" )
      fields << "#{saon},"
    end

    if (paon = value_of_property( "ppd:propertyAddressPaon" )) && paon != "no_value"
      paon_tokens = format_paon_elements( paon )
      comma_not_needed = paon_tokens.last =~ /\d/
      fields << "#{paon_tokens.join(' ')}#{comma_not_needed ? "" : ","}"
    end

    %w(
      ppd:propertyAddressStreet
      ppd:propertyAddressTown
    ).each do |p|
      if f = presentation_value_of_property( p )
        fields << "#{f},"
      end
    end

    if (postcode = value_of_property( "ppd:propertyAddressPostcode" )) && postcode != "no_value"
      fields << postcode
    end

    fields.join( " " ).html_safe
  end

  def group_heading( previous )
    gk = group_key
    if !previous || gk != previous.group_key
      gk.select {|v| v}.join( ", ")
    end
  end

  def group_key
    GROUP_HEADING_PROPERTIES.map {|p| value_of_property p}
  end

  private

  def index_key_value( p )
    v = @result[p]
    return "no_value" unless v
    return "no_value" if empty_string?( v )
    value_of( v )
  end

  def value_of( v )
    if v.kind_of?( Array )
      v = v.empty? ? "no_value" : v.first
    end

    v = (v["@value"] || "no_value") if v.kind_of?( Hash )
    empty_string?( v ) ? "no_value" : v
  end

  def id_of( v )
    if v.kind_of?( Array )
      v = v.empty? ? "no_value" : v.first
    end

    v = (v["@id"] || "no_value") if v.kind_of?( Hash )
    empty_string?( v ) ? "no_value" : v
  end

  def empty_string?( v )
    v.kind_of?(String) && v.empty?
  end

  def title_case_exception?( p )
    p == "ppd:propertyAddressPostcode"
  end

  def format_paon_elements( paon )
    paon.split( ' ' ).map do |token|
      case token
      when /\d/
        token
      when "-"
        "&ndash;"
      else
        token.titlecase
      end
    end
  end

  def titlecase_with_hyphens( str )
    str.split( "-" ).map( &:titlecase ).join( "-" )
  end

  def is_no_value?( v )
    v.nil? || v == "no_value"
  end
end
