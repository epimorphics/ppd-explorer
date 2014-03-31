module PpdHelper

  def address_detail_header( aspect, result )
    if result.presentation_value_of_property( aspect.aspect_key_property )
      content_tag( "th" ) do
        aspect.key_as_label
      end
    end
  end

  def address_detail_filter( aspect, result, preferences )
    if vp = result.presentation_value_of_property( aspect.aspect_key_property )
      val = result.value_of_property( aspect.aspect_key_property )

      content_tag( "td" ) do
        concat vp

        unless preferences.present?( aspect.key )
          concat(
            content_tag( :a, {href: preferences.as_path( :search, {aspect.key => val} )}, class: "btn btn-lg btn-default" ) do
              content_tag( :i, nil, class: "fa fa-search-plus" )
            end
          ).html_safe
        end

      end
    end
  end

end
