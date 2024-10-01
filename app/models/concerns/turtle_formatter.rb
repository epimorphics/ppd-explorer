# frozen_string_literal: true

# Module for formatting a record as Turtle
module TurtleFormatter
  def each_property(result, ignore_pattern = nil, &block)
    props = result_to_ttl(result)[:properties]
    props.reject { |pv| ignore_pattern && pv[:p] =~ ignore_pattern }.each(&block)
  end

  def result_to_ttl(result)
    ttl_value = { properties: [] }

    result.map do |property, value|
      next if value.respond_to?(:empty?) && value.empty?

      if property == '@id'
        ttl_value[:uri] = format_ttl_value(value)
      else
        ttl_value[:properties] << { p: format_ttl_value(property),
                                    v: format_ttl_value(value) }
      end
    end

    ttl_value
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
  def format_ttl_value(value)
    f =
      if value.nil?
        ''
      elsif value.is_a?(Array)
        value.map { |v| format_ttl_value(v) }.join(', ')
      elsif value.is_a? Numeric
        value.to_s
      elsif value.respond_to?(:match?) && value.match?(%r{\Ahttp://.*})
        "<#{value}>"
      elsif value.respond_to?(:match?) && value.match?(/\A[[:word:]]+:.*/)
        value.to_s
      elsif [false, true].include?(value)
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
        "\"#{value}\"^^<#{value.class.name}> # warning: default formatting rule (likely a bug)"
      end

    f.html_safe
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
end
