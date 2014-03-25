class QueryCommand < DataService
  attr_reader :all_results

  ASPECTS = {
    paon:       SearchAspect.new( :paon,     "ppd:propertyAddress", key_property: "lrcommon:paon" ),
    street:     SearchAspect.new( :street,   "ppd:propertyAddress", key_property: "lrcommon:street" ),
    town:       SearchAspect.new( :town,     "ppd:propertyAddress", key_property: "lrcommon:town" ),
    locality:   SearchAspect.new( :locality, "ppd:propertyAddress", key_property: "lrcommon:locality" ),
    district:   SearchAspect.new( :district, "ppd:propertyAddress", key_property: "lrcommon:district" ),
    county:     SearchAspect.new( :county,   "ppd:propertyAddress", key_property: "lrcommon:county" ),
    postcode:   SearchAspect.new( :postcode, "ppd:propertyAddress", key_property: "lrcommon:postcode" ),
    ptype:      FilterAspect.new( :ptype,    "ppd:propertyType",    values: %w{lrcommon:detached lrcommon:semi-detached lrcommon:terraced lrcommon:flat-maisonette } ),
    nb:         FilterAspect.new( :nb,       "ppd:newBuild",        values: %w{true false} ),
    ten:        FilterAspect.new( :ten,      "ppd:estateType",      values: %w{lrcommon:freehold lrcommon:leasehold} ),
    min_price:  RangeAspect.new( :min_price, "ppd:purchasePrice",   operator: "@ge" ),
    max_price:  RangeAspect.new( :max_price, "ppd:purchasePrice",   operator: "@le" ),
    min_date:   RangeAspect.new( :min_date,  "ppd:transactionDate", operator: "@ge" ),
    max_date:   RangeAspect.new( :max_date,  "ppd:transactionDate", operator: "@le" )
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
  end

end
