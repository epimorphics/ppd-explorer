# frozen_string_literal: true

# Concern for formatting DSApi results as input to a Turtle template
module DsapiTurtleFormatter
  def turtle_resources
    resources = []

    [search_id_0, search_id_1].each do |search_id|
      results = @all_results[search_id.sym]
      resources.concat results_to_ttl(results) if results
    end

    resources
  end

  def results_to_ttl(results)
    results.map { |r| result_to_ttl(r) }
  end

  def result_to_ttl(result) # rubocop:disable Metrics/MethodLength
    ttl_value = { properties: [] }

    result.map do |property, value|
      next if value.respond_to?(:size) && value.empty?

      if property == '@id'
        ttl_value[:uri] = format_ttl_value(value)
      else
        ttl_value[:properties] << { p: format_ttl_value(property),
                                    v: format_ttl_value(value) }
      end
    end

    ttl_value
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
  def format_ttl_value(value)
    f =
      if value.is_a?(Array)
        value.map { |v0| format_ttl_value v0 } .join(', ')
      elsif value.is_a? Numeric
        value.to_s
      elsif value.match?(%r{\Ahttp://.*})
        "<#{value}>"
      elsif value.match?(/\A[[:word:]]+:.*/)
        value.to_s
      elsif value['@id']
        "<#{value['@id']}>"
      elsif value['@value'] && value['@type']
        "\"#{value['@value']}\"^^#{format_ttl_value(value['@type'])}"
      elsif value['@value']
        "\"#{value['@value']}\""
      elsif value.is_a? String
        "\"#{value}\""
      else
        "\"#{value}\"^^<#{value.class.name}> # warning: default formatting rule"
      end

    f.html_safe
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
end
