# Adapter pattern for search result, which presents a linked-data
# resource in the standard format LR use for downloading PPD results
class DownloadRecord
  attr_reader :search_result

  DOWNLOAD_COLUMNS = [
    {aspect_property: "ppd:transactionId",
     header: "unique_id"
    },
    {aspect_property: "ppd:pricePaid",
     header: "price_paid"
    },
    {aspect_property: "ppd:transactionDate",
     header: "deed_date"
    },
    {aspect_property: "ppd:propertyAddressPostcode",
     header: "postcode"
    },
    {aspect_property: "ppd:propertyType",
     codes: {"lrcommon:detached" => "D",
             "http://landregistry.data.gov.uk/def/common/detached" => "D",
             "lrcommon:semi-detached" => "S",
             "http://landregistry.data.gov.uk/def/common/semi-detached" => "S",
             "lrcommon:terraced" => "T",
             "http://landregistry.data.gov.uk/def/common/terraced" => "T",
             "lrcommon:flat-maisonette" => "F",
             "http://landregistry.data.gov.uk/def/common/flat-maisonette" => "F"
            },
     header: "property_type"
    },
    {aspect_property: "ppd:newBuild",
     codes: {"true" => "Y",
             true => "Y",
             "false" => "N",
             false => "N"
            },
     header: "new_build"
    },
    {aspect_property: "ppd:estateType",
     codes: {"lrcommon:freehold" => "F",
             "http://landregistry.data.gov.uk/def/common/freehold" => "F",
             "lrcommon:leasehold" => "L",
             "http://landregistry.data.gov.uk/def/common/leasehold" => "L"
            },
     header: "estate_type"
    },
    {aspect_property: "ppd:propertyAddressSaon",
     header: "saon"
    },
    {aspect_property: "ppd:propertyAddressPaon",
     header: "paon"
    },
    {aspect_property: "ppd:propertyAddressStreet",
     header: "street"
    },
    {aspect_property: "ppd:propertyAddressLocality",
     header: "locality"
    },
    {aspect_property: "ppd:propertyAddressTown",
     header: "town"
    },
    {aspect_property: "ppd:propertyAddressDistrict",
     header: "district"
    },
    {aspect_property: "ppd:propertyAddressCounty",
     header: "county"
    },
    {aspect_property: "@id",
     header: "linked_data_uri"
    },
  ]

  def initialize( sr )
    @search_result = sr
  end

  def each_column( &block )
    DOWNLOAD_COLUMNS.each_with_index do |col, i|
      yield column_value( col, i )
    end
  end

  private

  def column_value( col, i )
    quoted( comma_separator( i ), coded_value_of( col ) ).html_safe
  end

  def quoted( sep, v )
    "#{sep}\"#{v.to_s.gsub( /"/, '\\"' )}\""
  end

  def coded_value_of( col )
    if codes = col[:codes]
      id = id_of( col[:aspect_property] )
      codes[id] || id
    else
      value_of( col[:aspect_property] )
    end
  end

  def value_of( p )
    v = search_result.value_of_property( p )
    (v == "no_value") ? "" : v
  end

  def id_of( p )
    search_result.id_of_property( p )
  end

  def comma_separator( i )
    (i > 0) ? "," : ""
  end

end
