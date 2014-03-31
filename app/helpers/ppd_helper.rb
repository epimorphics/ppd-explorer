module PpdHelper

  def address_detail_header( addr_f, result )
    if result.presentation_value_of_property( addr_f.first )
      content_tag( "th" ) do
        addr_f.second
      end
    end
  end

  def address_detail_filter( addr_f, result )
    if v = result.presentation_value_of_property( addr_f.first )
      content_tag( "td" ) do
        v
      end
    end
  end
end
