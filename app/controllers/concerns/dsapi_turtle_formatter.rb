# Concern for formatting DSApi results as input to a Turtle template
module DsapiTurtleFormatter
  def turtle_resources
    resources = []

    [search_id_0, search_id_1].each do |search_id|
      results =  @all_results[search_id.sym]
      resources.concat results_to_ttl( results ) if results
    end

    resources
  end

  def results_to_ttl( results )
    results.map {|r| result_to_ttl( r )}
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
      if v.is_a?( Array )
        v.map {|v| format_ttl_value v} .join( ", " )
      elsif v.is_a? Numeric
        v.to_s
      elsif v =~ /\Ahttp:\/\/.*/
        "<#{v.to_s}>"
      elsif v =~ /\A[[:word:]]+:.*/
        v.to_s
      elsif v["@id"]
        "<#{v["@id"]}>"
      elsif v["@value"] && v["@type"]
        "\"#{v["@value"]}\"^^#{format_ttl_value( v["@type"] )}"
      elsif v["@value"] &&
        "\"#{v["@value"]}\""
      elsif v.is_a? String
        "\"#{v}\""
      else
        "\"#{v.to_s}\"^^<#{v.class.name}> # warning: default formatting rule (likely to be a bug)"
      end

    f.html_safe
  end
end
