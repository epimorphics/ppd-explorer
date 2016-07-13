# frozen_string_literal: true

class SearchResults
  include ActionView::Helpers::TextHelper
  attr_reader :index, :transactions, :max_results_limit_hit

  DEFAULT_MAX_RESULTS = 5000

  def initialize( results_json, max )
    @index = autokey_hash
    @properties = Set.new
    @transactions = 0
    index_results( results_json, max || DEFAULT_MAX_RESULTS )
  end

  # Traverse the index values in sort order, and yield each transaction
  # in order
  def each_transaction( &block )
    traverse_in_sort_order( index, &block )
  end

  # Traverse the index values in sort order, and yield a list of transactions
  # for one address
  def each_property_address( &block )
    traverse_property_addresses( index, &block )
  end

  def summarise
    if @count_phrase
      "Showing #{pluralize transactions, "transaction"} (from #{@count_phrase} matching transactions) for #{pluralize properties, "property"}"
    else
      "Found #{pluralize transactions, "transaction"} for #{pluralize properties, "property"}"
    end
  end

  def query_count( count_phrase )
    @count_phrase = count_phrase
  end

  def properties
    @properties.size
  end

  alias :size :transactions

  private

  def index_results( results, max )
    results.each_with_index do |result, i|
      @max_results_limit_hit = true if i >= max
      index_result( SearchResult.new( result ), @max_results_limit_hit )
    end
  end

  def index_result( result, count_only )
    @transactions += 1
    @properties << result.key_hash

    key = result.key.clone
    last = key.pop
    ind = key.reduce( index ) {|i,k| i[k]}

    unless count_only
      ind[last] = [] unless ind.has_key?( last )
      ind[last] << result
    end
  end

  def autokey_hash
    Hash.new {|h,k| h[k] = autokey_hash}
  end

  # TODO DRY
  def traverse_in_sort_order( index, &block )
    index.keys.sort.each do |key|
      v = index[key]

      if v.kind_of?( Hash )
        traverse_in_sort_order( v, &block )
      else
        traverse_in_date_order( v, &block )
      end
    end
  end

  # TODO DRY
  def traverse_property_addresses( index, &block )
    index.keys.sort.each do |key|
      v = index[key]

      if v.kind_of?( Hash )
        traverse_property_addresses( v, &block )
      else
        yield v.sort!.reverse
      end
    end
  end

  def traverse_in_date_order( search_results, &block )
    st = search_results.sort!
    st.reverse.each &block
  end
end

