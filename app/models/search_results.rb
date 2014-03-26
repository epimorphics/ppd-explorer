class SearchResults
  attr_reader :index

  def initialize( results_json )
    @index = autokey_hash
    index_results( results_json )
  end

  # Traverse the index values in sort order, and yield each transaction
  # in order
  def each_transaction( &block )
    traverse_in_sort_order( index, &block )
  end

  private

  def index_results( results )
    results.each do |result|
      index_result( SearchResult.new( result ) )
    end
  end

  def index_result( result )
    key = result.key
    last = key.pop
    ind = key.reduce( index ) {|i,k| i[k]}

    if ind.has_key?( last )
      ind[last] << result
    else
      ind[last] = [result]
    end
  end

  def autokey_hash
    Hash.new {|h,k| h[k] = autokey_hash}
  end

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

  def traverse_in_date_order( search_results, &block )
    st = search_results.sort
    st.reverse.each &block
  end
end

