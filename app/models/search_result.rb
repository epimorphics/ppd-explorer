# An individual result returned from the search service
class SearchResult

  INDEX_KEY_PROPERTIES =
      %w(
        ppd:propertyAddressCounty
        ppd:propertyAddressLocality
        ppd:propertyAddressDistrict
        ppd:propertyAddressTown
        ppd:propertyAddressStreet
        ppd:propertyAddressPaon
        ppd:propertyAddressSaon
      )

  PROPERTY_DETAILS_PROPERTIES = %w(
    ppd:propertyType

  )

  def initialize( resultJson )
    @result = resultJson
  end

  def key
    @key ||= INDEX_KEY_PROPERTIES.map {|p| index_key_value( p )}
  end

  def <=>( sr )
    transaction_date <=> sr.transaction_date
  end

  def transaction_date
    @transaction_date ||= Date.parse( value_of_property( "ppd:transactionDate" ))
  end

  def value_of_property( p )
    value_of( @result[p] )
  end

  def id_of_property( p )
    id_of( @result[p] )
  end

  def different_key?( sr )
    key != sr.key
  end

  def property_details
    [property_type, tenure, new_build]
  end

  def property_type
    pt = id_of_property( "ppd:propertyType" )
    {uri: pt, label: pt.gsub( /\A.*\//, "" )}
  end

  def tenure
    ten = id_of_property( "ppd:estateType" )
    {uri: ten, label: ten.gsub( /\A.*\//, "" )}
  end

  def new_build
    nb = value_of_property( "ppd:estateType" )
    if nb == "false" || nb == false || nb == "no_value"
      {label: "not new-build"}
    else
      {label: "new-build"}
    end
  end

  def address_fields
    INDEX_KEY_PROPERTIES.reverse
                        .map {|p| value_of_property( p )}
                        .reject {|v| ["no_value", ""].include?( v )}
                        .map &:downcase
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


end
