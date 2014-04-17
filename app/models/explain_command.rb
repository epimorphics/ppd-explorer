class ExplainCommand < QueryCommand
  attr_reader :explanation

  def load_explanation( options = {} )
    ppd = dataset( :ppd )
    query = assemble_query

    if limit = query_limit
      query = query.limit( limit )
    end

    Rails.logger.debug "About to ask DsAPI to explain: #{query.to_json}"

    @explanation = ppd.explain( query ).with_indifferent_access
  end

end
