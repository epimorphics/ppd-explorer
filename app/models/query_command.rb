class QueryCommand < DataService
  attr_reader :all_results, :search_results

  ASPECTS = {
    saon:       SearchAspect.new( :saon,
                                  "ppd:propertyAddress",
                                  key_property: "lrcommon:saon",
                                  aspect_key_property: "ppd:propertyAddressSaon",
                                  presentation_label: "secondary name" ),
    paon:       SearchAspect.new( :paon,
                                  "ppd:propertyAddress",
                                  key_property: "lrcommon:paon",
                                  aspect_key_property: "ppd:propertyAddressPaon",
                                  presentation_label: "house name or no." ),
    street:     SearchAspect.new( :street,
                                  "ppd:propertyAddress",
                                  key_property: "lrcommon:street",
                                  aspect_key_property: "ppd:propertyAddressStreet" ),
    town:       SearchAspect.new( :town,
                                  "ppd:propertyAddress",
                                  key_property: "lrcommon:town",
                                  aspect_key_property: "ppd:propertyAddressTown" ),
    locality:   SearchAspect.new( :locality,
                                  "ppd:propertyAddress",
                                  key_property: "lrcommon:locality",
                                  aspect_key_property: "ppd:propertyAddressLocality" ),
    district:   SearchAspect.new( :district,
                                  "ppd:propertyAddress",
                                  key_property: "lrcommon:district",
                                  aspect_key_property: "ppd:propertyAddressDistrict" ),
    county:     SearchAspect.new( :county,
                                  "ppd:propertyAddress",
                                  key_property: "lrcommon:county",
                                  aspect_key_property: "ppd:propertyAddressCounty" ),
    postcode:   SearchAspect.new( :postcode,
                                  "ppd:propertyAddress",
                                  key_property: "lrcommon:postcode",
                                  aspect_key_property: "ppd:propertyAddressPostcode" ),
    ptype:      FilterAspect.new( :ptype,
                                  "ppd:propertyType",
                                  values: %w{lrcommon:detached lrcommon:semi-detached lrcommon:terraced lrcommon:flat-maisonette },
                                  uri_value: true,
                                  presentation_label: "property type" ),
    nb:         FilterAspect.new( :nb,
                                  "ppd:newBuild",
                                  values: %w{true false},
                                  uri_value: false,
                                  value_type: "xsd:boolean",
                                  presentation_label: "new build?" ),
    ten:        FilterAspect.new( :ten,
                                  "ppd:estateType",
                                  values: %w{lrcommon:freehold lrcommon:leasehold},
                                  uri_value: true,
                                  presentation_label: "tenancy" ),
    min_price:  RangeAspect.new( :min_price,
                                  "ppd:pricePaid",
                                  operator: "@ge",
                                  presentation_label: "minimum price",
                                  value_type: :numeric,
                                  prompt: "%s is &pound;%s" ),
    max_price:  RangeAspect.new( :max_price,
                                  "ppd:pricePaid",
                                  operator: "@le",
                                  presentation_label: "maximum price",
                                  value_type: :numeric,
                                  prompt: "%s is &pound;%s" ),
    min_date:   RangeAspect.new( :min_date,
                                  "ppd:transactionDate",
                                  operator: "@ge",
                                  presentation_label: "earliest date",
                                  value_type: :date ),
    max_date:   RangeAspect.new( :max_date,
                                  "ppd:transactionDate",
                                  operator: "@le",
                                  presentation_label: "latest date",
                                  value_type: :date )
  }

  def assemble_query
    ASPECTS.values.reduce( base_query ) do |query, aspect|
      aspect.present?( preferences ) ? aspect.add_clause( query, preferences ) : query
    end
  end

  def load_query_results( options = {} )
    ppd = dataset( :ppd )
    query = assemble_query

    Rails.logger.debug "About to ask DsAPI query: #{query.to_json}"

    @all_results = ppd.query( query )
    @search_results = SearchResults.new( @all_results )
  end

end
