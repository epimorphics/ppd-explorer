module TurtleFormatter
  def each_property( result, ignore_pattern = nil, &block )
    props = result_to_ttl( result )[:properties]
    props.reject {|pv| ignore_pattern && pv[:p] =~ ignore_pattern}.each( &block )
  end

  def result_to_ttl( result )
    ttl_value = {properties: []}

    result.map do |property, value|
      next if value.respond_to?(:size) && value.size == 0
      if property == "@id"
        ttl_value[:uri] = format_ttl_value( value )
      else
        ttl_value[:properties] << {p: format_ttl_value( property ),
                                   v: format_ttl_value( value )}
      end
    end

    ttl_value
  end

  def format_ttl_value( v )
    f =
      if v == nil
        nil
      elsif v.is_a?( Array )
        v.map {|v| format_ttl_value v} .join( ", " )
      elsif v.is_a? Numeric
        v.to_s
      elsif v =~ /\Ahttp:\/\/.*/
        "<#{v.to_s}>"
      elsif v =~ /\A[[:word:]]+:.*/
        v.to_s
      elsif [false,true].include?( v )
        v.to_s
      elsif v["@id"]
        "<#{v["@id"]}>"
      elsif v["@value"] && v["@type"]
        "\"#{v["@value"]}\"^^#{format_ttl_value( v["@type"] )}"
      elsif v["@value"]
        "\"#{v["@value"]}\""
      else
        "default #{v.to_s}"
      end

    f.html_safe
  end
end
