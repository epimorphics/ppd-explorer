# frozen_string_literal: true

# Encapsulates a collection of results from a user query
class SearchResults
  include ActionView::Helpers::TextHelper
  attr_reader :index, :transactions, :max_results_limit_hit

  DEFAULT_MAX_RESULTS = 5000

  def initialize(results_json, max)
    @index = AutoExtendHash.new
    @properties = Set.new
    @transactions = 0
    index_results(results_json, max || DEFAULT_MAX_RESULTS)
  end

  # Traverse the index values in sort order, and yield each transaction
  # in order
  def each_transaction(&block)
    traverse_in_sort_order(index, &block)
  end

  # Traverse the index values in sort order, and yield a list of transactions
  # for one address
  def each_property_address(&block)
    traverse_property_addresses(index, &block)
  end

  def summarise
    if @count_phrase
      # rubocop:disable Layout/LineLength
      "Showing #{pluralize transactions, 'transaction'} (from #{@count_phrase} matching transactions) for #{pluralize properties, 'property'}"
      # rubocop:enable Layout/LineLength
    else
      "Found #{pluralize transactions, 'transaction'} for #{pluralize properties, 'property'}"
    end
  end

  def query_count(count_phrase)
    @count_phrase = count_phrase
  end

  def properties
    @properties.size
  end

  alias size transactions

  private

  def index_results(results, max)
    results.each_with_index do |result, i|
      @max_results_limit_hit = true if i >= max
      index_result(SearchResult.new(result), @max_results_limit_hit)
    end
  end

  def index_result(result, count_only)
    @transactions += 1
    @properties << result.key_hash

    key = result.key.clone
    last = key.pop
    ind = key.reduce(index) { |i, k| i[k] }

    return if count_only

    ind[last] = [] unless ind.key?(last)
    ind[last] << result
  end

  # TODO: DRY
  def traverse_in_sort_order(index, &block)
    index.keys.sort.each do |key|
      v = index[key]

      if v.is_a?(Hash)
        traverse_in_sort_order(v, &block)
      else
        traverse_in_date_order(v, &block)
      end
    end
  end

  # TODO: DRY
  def traverse_property_addresses(index, &block)
    index.keys.sort.each do |key|
      v = index[key]

      if v.is_a?(Hash)
        traverse_property_addresses(v, &block)
      else
        yield v.sort!.reverse
      end
    end
  rescue StandardError => e
    Rails.logger.debug "Error in search_results: #{e.inspect}"
  end

  def traverse_in_date_order(search_results, &block)
    st = search_results.sort!
    st.reverse.each(&block)
  end
end
