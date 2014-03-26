class SearchResults
  attr_reader :index

  INDEX_KEY_PROPERTIES =
      %w(
        ppd:propertyAddressCounty
        ppd:propertyAddressLocality
        ppd:propertyAddressDistrict
        ppd:propertyAddressTown
        ppd:propertyAddressStreet
        ppd:propertyAddressPaon
        ppd:propertyAddressSaon
      )

  def initialize( results_json )
    @index = autokey_hash
    index_results( results_json )
  end

  # Traverse the index values in sort order, and yield each list
  # of indexed results
  def traverse( &block )
    traverse_in_sort_order( index, &block )
  end

  private

  def index_results( results )
    results.each do |result|
      index_result( result )
    end
  end

  def index_result( result )
    key = index_key( result )
    last = key.pop
    ind = key.reduce( index ) {|i,k| i[k]}

    if ind.has_key?( last )
      ind[last] << result
    else
      ind[last] = [result]
    end
  end

  def index_key( result )
    INDEX_KEY_PROPERTIES.map do |p|
      index_key_value( p, result )
    end
  end

  def index_key_value( p, result )
    v = result[p]
    return :no_value unless v
    return :no_value if empty_string?( v )
    value_of( v )
  end

  def value_of( v )
    v = (v["@value"] || :no_value) if v.kind_of?( Hash )
    empty_string?( v ) ? :no_value : v
  end

  def autokey_hash
    Hash.new {|h,k| h[k] = autokey_hash}
  end

  def empty_string?( v )
    v.kind_of?(String) && v.empty?
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

  def traverse_in_date_order( transactions, &block )
    st = transactions.sort do |t0,t1|
      d0 = t0["ppd:transactionDate"]["@value"]
      d1 = t1["ppd:transactionDate"]["@value"]

      Date.parse( d0 ) <=> Date.parse( d1 )
    end

    st.reverse.each &block
  end
end

