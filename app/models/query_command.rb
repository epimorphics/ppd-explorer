# frozen_string_literal: true

# Command object providing a service for driving the DsAPI
# rubocop:disable Metrics/ClassLength
class QueryCommand < DataService
  include TurtleFormatter

  attr_reader :all_results, :search_results, :error_message
  COUNT_LIMIT = 10_000

  ASPECTS = {
    saon:       SearchAspect.new(:saon,
                                 'ppd:propertyAddress',
                                 key_property: 'lrcommon:saon',
                                 aspect_key_property: 'ppd:propertyAddressSaon',
                                 presentation_label: 'secondary name'),
    paon:       SearchAspect.new(:paon,
                                 'ppd:propertyAddress',
                                 key_property: 'lrcommon:paon',
                                 aspect_key_property: 'ppd:propertyAddressPaon',
                                 presentation_label: 'building name or no.'),
    street:     SearchAspect.new(:street,
                                 'ppd:propertyAddress',
                                 key_property: 'lrcommon:street',
                                 aspect_key_property: 'ppd:propertyAddressStreet'),
    town:       SearchAspect.new(:town,
                                 'ppd:propertyAddress',
                                 key_property: 'lrcommon:town',
                                 aspect_key_property: 'ppd:propertyAddressTown'),
    locality:   SearchAspect.new(:locality,
                                 'ppd:propertyAddress',
                                 key_property: 'lrcommon:locality',
                                 aspect_key_property: 'ppd:propertyAddressLocality'),
    district:   SearchAspect.new(:district,
                                 'ppd:propertyAddress',
                                 key_property: 'lrcommon:district',
                                 aspect_key_property: 'ppd:propertyAddressDistrict'),
    county:     SearchAspect.new(:county,
                                 'ppd:propertyAddress',
                                 key_property: 'lrcommon:county',
                                 aspect_key_property: 'ppd:propertyAddressCounty'),
    postcode:   SearchAspect.new(:postcode,
                                 'ppd:propertyAddress',
                                 key_property: 'lrcommon:postcode',
                                 aspect_key_property: 'ppd:propertyAddressPostcode'),
    ptype:      FilterAspect.new(:ptype,
                                 'ppd:propertyType',
                                 values: %w[
                                   lrcommon:detached
                                   lrcommon:semi-detached
                                   lrcommon:terraced
                                   lrcommon:flat-maisonette
                                   lrcommon:otherPropertyType
                                 ],
                                 uri_value: true,
                                 presentation_label: 'property type'),
    nb:         FilterAspect.new(:nb,
                                 'ppd:newBuild',
                                 values: %w[true false],
                                 uri_value: false,
                                 value_type: 'xsd:boolean',
                                 presentation_label: 'new build?',
                                 value_labels: {
                                   'true' => 'new build only',
                                   'false' => 'existing buildings only'
                                 }),
    et:         FilterAspect.new(:et,
                                 'ppd:estateType',
                                 values: %w[lrcommon:freehold lrcommon:leasehold],
                                 uri_value: true,
                                 presentation_label: 'estate type'),
    tc:         FilterAspect.new(:tc,
                                 'ppd:transactionCategory',
                                 values: %w[
                                   ppd:standardPricePaidTransaction
                                   ppd:additionalPricePaidTransaction
                                 ],
                                 uri_value: true,
                                 presentation_label: 'transaction category'),
    min_price:   RangeAspect.new(:min_price,
                                 'ppd:pricePaid',
                                 operator: '@ge',
                                 presentation_label: 'minimum price',
                                 value_type: :numeric,
                                 prompt: '%s is &pound;%s'),
    max_price:   RangeAspect.new(:max_price,
                                 'ppd:pricePaid',
                                 operator: '@le',
                                 presentation_label: 'maximum price',
                                 value_type: :numeric,
                                 prompt: '%s is &pound;%s'),
    min_date:    RangeAspect.new(:min_date,
                                 'ppd:transactionDate',
                                 operator: '@ge',
                                 presentation_label: 'on or after',
                                 value_type: :date),
    max_date:    RangeAspect.new(:max_date,
                                 'ppd:transactionDate',
                                 operator: '@le',
                                 presentation_label: 'on or before',
                                 value_type: :date)
  }.freeze

  def initialize(preferences, compact = false)
    super(preferences, compact)
  end

  def assemble_query
    ASPECTS.values.reduce(base_query) do |query, aspect|
      aspect.present?(preferences) ? aspect.add_clause(query, preferences) : query
    end
  end

  def load_query_results(options = {})
    ppd = dataset(:ppd)
    query = assemble_query
    limit = query_limit

    if limit
      base_query = query
      query = query.limit(limit)
      count_query = base_query.count_only.limit(COUNT_LIMIT)
    end

    save_results(ppd, query, options)

    add_count_information(ppd, count_query) if reached_count_limit?(limit)
  end

  def self.find_aspect(key)
    ASPECTS[key]
  end

  def query_limit
    (l = preferences.selected_limit) =~ /\d/ && l.to_i
  end

  def save_results(ppd, query, options)
    # Rails.logger.debug "About to ask DsAPI query: #{query.to_json}"
    @all_results = ppd.query(query)
    @search_results = SearchResults.new(@all_results, options[:max])
  end

  def reached_count_limit?(limit)
    limit && @search_results.size >= limit
  end

  def add_count_information(ppd, count_query)
    count_result = ppd.query(count_query)
    count = count_result.first['@count']
    @search_results.query_count("#{count}#{count == COUNT_LIMIT ? ' or more' : ''}")
  end

  def success?
    !error_message
  end
end
