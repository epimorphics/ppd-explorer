# frozen_string_literal: true

# Model to encapsulate user's search preferences
class UserPreferences
  include Rails.application.routes.url_helpers

  WHITE_LIST = QueryCommand::ASPECTS.map do |key, aspect|
    aspect.values ? { key => [] } : key
  end + %i(search limit header explain)

  DEFAULT_LIMIT = "100".freeze
  AVAILABLE_LIMITS = [DEFAULT_LIMIT, "1000", "all"].freeze

  def initialize(user_params)
    @params = user_params.permit(WHITE_LIST).to_h
    sanitise!
  end

  def param(p)
    val = @params[p]
    val == "" ? nil : val
  end

  # Return truthy if parameter p is present, optionally with value v
  def present?(p, v = nil)
    if v
      param_value = param(p)
      param_value.is_a?(Array) ? param_value.include?(v) : (param_value == v)
    else
      param(p)
    end
  end

  # Yield a block to each search term with a non-empty value
  def each_search_term
    QueryCommand::ASPECTS.each do |_key, aspect|
      (aspect.option(:values) || [nil]).each do |value|
        yield aspect.search_term(value, self) if aspect.present?(self, value)
      end
    end
  end

  # Return true if there are no params set
  def empty?
    QueryCommand::ASPECTS.keys.reduce(true) do |acc, aspect_name|
      acc && !present?(aspect_name)
    end
  end

  # Return the current preferences as arguments to the given controller path
  def as_path(controller, options = {}, remove = {})
    path_params = @params.merge(options)
    process_removes(path_params, remove)
    action = :index

    case controller
    when :ppd_data
      action = :show
    when :view
      # an artefact of lr-common-styles layout template
      controller = :ppd
    end

    url_for(path_params.merge(controller: controller, action: action, only_path: true))
  end

  # Return true if a given option should be displayed as checked, given the
  # state of the user's selections
  def display_checked?(key, value)
    QueryCommand.find_aspect(key).display_checked?(self, value)
  end

  # Return the currentely selected limit on number of queries, or the default
  def selected_limit
    param("limit") || DEFAULT_LIMIT
  end

  # Return true if the user has unlimited data
  def unlimited?
    selected_limit == "all"
  end

  private

  # Remove any non-whitelisted parameters, or params with empty values
  def sanitise!
    @params.keep_if do |_k, v|
      !v.to_s.strip.empty?
    end
  end

  # Process any instructions to remove a value from the params
  def process_removes(pparams, removes)
    removes.each do |r, v|
      if pparams[r].is_a?(Array)
        pparams[r] -= [v]
        pparams.delete(r) if pparams[r].empty?
      else
        pparams.delete(r)
      end
    end
  end
end
