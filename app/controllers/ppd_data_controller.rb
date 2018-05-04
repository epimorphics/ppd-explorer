# frozen_string_literal: true

# Controller for downloading data
class PpdDataController < ApplicationController
  include DsapiTurtleFormatter
  MAX_DOWNLOAD_RESULTS = 1_000_000

  rescue_from MalformedSearchError, with: :render_malformed_search_error

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def show
    @preferences = UserPreferences.new(params)
    template = choose_template

    if is_explanation?
      explanation = ExplainCommand.new(@preferences).load_explanation
      redirect_to "/app/hpi/qonsole?q=#{URI.encode_www_form_component(explanation[:sparql])}"
    else
      if is_data_request?
        @query_command = QueryCommand.new(@preferences)
        @query_command.load_query_results(limit: :all, download: true, max: MAX_DOWNLOAD_RESULTS)

        template = 'ppd/error' unless @query_command.success?
      end

      render template
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def is_explanation? # rubocop:disable Style/PredicateName
    params[:explain]
  end

  def is_data_request? # rubocop:disable Style/PredicateName
    request.format == Mime::Type.lookup_by_extension(:ttl) ||
      request.format == Mime::Type.lookup_by_extension(:csv)
  end

  def choose_template
    template = 'show'

    if @preferences.param('header')
      template = 'show_with_header'
      @header = ''

      DownloadRecord::DOWNLOAD_COLUMNS.each_with_index do |col, i|
        @header << ',' if i.positive?
        @header << col[:header]
      end
    end

    template
  end

  def render_malformed_search_error(exception = nil)
    uuid = SecureRandom.uuid

    Rails.logger.error "Malformed search error #{uuid} :: #{exception&.message || 'no message'}"

    render nothing: true, status: 400
  end
end
