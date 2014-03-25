# Model to encapsulate user's search preferences
class UserPreferences
  ASPECTS = {
    paon:       {aspect: "ppd:propertyAddress", property: "lrcommon:paon"},
    street:     {aspect: "ppd:propertyAddress", property: "lrcommon:street"},
    town:       {aspect: "ppd:propertyAddress", property: "lrcommon:town"},
    locality:   {aspect: "ppd:propertyAddress", property: "lrcommon:locality"},
    district:   {aspect: "ppd:propertyAddress", property: "lrcommon:district"},
    county:     {aspect: "ppd:propertyAddress", property: "lrcommon:county"},
    postcode:   {aspect: "ppd:propertyAddress", property: "lrcommon:postcode"},
    ptype:      {aspect: "ppd:propertyType"},
    nb:         {aspect: "ppd:newBuild"}
    ten:        {aspect: "ppd:estateType"}
  }
   WHITE_LIST = (ASPECTS.keys +
                 %w(min_price max_price
                    min_date max_date
                   )
               ).map( &:to_s )

  def intitialize( p )
    @params = indifferent_access( p )
    sanitise!
  end

  private

  def whitelist_params
    WHITE_LIST
  end

  def whitelisted?( param )
    whitelist_params.include?( param.to_s )
  end

  # Remove any non-whitelisted parameters
  def sanitise!
    @params.keep_if {|k,v| whitelisted? k}
  end




  def indifferent_access( h )
    h.is_a?( HashWithIndifferentAccess) ? h : HashWithIndifferentAccess.new( h )
  end

end
