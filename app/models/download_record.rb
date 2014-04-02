# Adapter pattern for search result, which presents a linked-data
# resource in the standard format LR use for downloading PPD results
class DownloadRecord
  attr_reader :search_result

  DOWNLOAD_COLUMNS = [
    {aspect_property: "@id" },
    {aspect_property: "ppd:pricePaid" },
    {aspect_property: "ppd:transactionDate" },
    {aspect_property: "ppd:propertyAddressPostcode" },
    {aspect_property: "ppd:propertyType",
     codes: {"lrcommon:detached" => "D",
             "http://landregistry.data.gov.uk/def/common/detached" => "D",
             "lrcommon:semi-detached" => "S",
             "http://landregistry.data.gov.uk/def/common/semi-detached" => "S",
             "lrcommon:terraced" => "T",
             "http://landregistry.data.gov.uk/def/common/terraced" => "T",
             "lrcommon:flat-maisonette" => "F",
             "http://landregistry.data.gov.uk/def/common/flat-maisonette" => "F"
            }
    },
    {aspect_property: "ppd:newBuild",
     codes: {"true" => "Y",
             true => "Y",
             "false" => "N",
             false => "N"
            }
    },
    {aspect_property: "ppd:estateType",
     codes: {"lrcommon:freehold" => "F",
             "http://landregistry.data.gov.uk/def/common/freehold" => "F",
             "lrcommon:leasehold" => "L",
             "http://landregistry.data.gov.uk/def/common/leasehold" => "L"
            }
    },
    {aspect_property: "ppd:propertyAddressSaon" },
    {aspect_property: "ppd:propertyAddressPaon" },
    {aspect_property: "ppd:propertyAddressStreet" },
    {aspect_property: "ppd:propertyAddressLocality" },
    {aspect_property: "ppd:propertyAddressTown" },
    {aspect_property: "ppd:propertyAddressDistrict" },
    {aspect_property: "ppd:propertyAddressCounty" }
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
