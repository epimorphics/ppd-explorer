# frozen_string_literal: true

module PpdHelper

  def address_detail_header( aspect, result )
    if result.presentation_value_of_property( aspect.aspect_key_property )
      content_tag( "td", class: "property-details-field-title" ) do
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
            content_tag( :a, {href: preferences.as_path( :search, {aspect.key => val} ), class: "search-zoom-button"}, {} ) do
              content_tag( :i, nil, class: "fa fa-search-plus" )
            end
          ).html_safe
        end

      end
    end
  end

  def results_selection( limit, preferences )
    if preferences.selected_limit == limit
      content_tag( "strong" ) do
        results_selection_summary( limit )
      end
    else
      content_tag( "a", {href: preferences.as_path( :search, {limit: limit} ), class: "btn btn-default btn-sm"} ) do
        results_selection_summary( limit )
      end
    end
  end

  def results_selection_summary( limit )
    (limit == "all") ? "all results" : "sample of (at most) #{limit} results"
  end
end
