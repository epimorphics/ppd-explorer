# frozen_string_literal: true

# Module for formatting a record as Turtle
module TurtleFormatter
  def each_property(result, ignore_pattern = nil, &block)
    props = result_to_ttl(result)[:properties]
    props.reject { |pv| ignore_pattern && pv[:p] =~ ignore_pattern }.each(&block)
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
  def format_ttl_value(v)
    f =
      if v.nil?
        ''
      elsif v.is_a?(Array)
        v.map { |v0| format_ttl_value v0 } .join(', ')
      elsif v.is_a? Numeric
        v.to_s
      elsif v.match?(%r{\Ahttp://.*})
        "<#{v}>"
      elsif v.match?(/\A[[:word:]]+:.*/)
        v.to_s
      elsif [false, true].include?(v)
        v.to_s
      elsif v['@id']
        "<#{v['@id']}>"
      elsif v['@value'] && v['@type']
        "\"#{v['@value']}\"^^#{format_ttl_value(v['@type'])}"
      elsif v['@value']
        "\"#{v['@value']}\""
      elsif v.is_a? String
        "\"#{v}\""
      else
        "\"#{v}\"^^<#{v.class.name}> # warning: default formatting rule (likely to be a bug)"
      end

    f.html_safe
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
end
