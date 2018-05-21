# frozen_string_literal: true

# Controller for downloading data
class PpdDataController < ApplicationController
  include DsapiTurtleFormatter
  MAX_DOWNLOAD_RESULTS = 1_000_000

  rescue_from MalformedSearchError, with: :render_malformed_search_error

  def show
    preferences = UserPreferences.new(params)

    if explanation?
      show_sparql_explanation(preferences)
    else
      prepare_data_download(preferences)
    end
  end

  def render_malformed_search_error(exception = nil)
    uuid = SecureRandom.uuid

    Rails.logger.error "Malformed search error #{uuid} :: #{exception&.message || 'no message'}"

    render nothing: true, status: 400
  end

  private

  def explanation?
    params[:explain]
  end

  def data_download?
    request.format == Mime::Type.lookup_by_extension(:ttl) ||
      request.format == Mime::Type.lookup_by_extension(:csv)
  end

  def create_download_header
    headers = DownloadRecord::DOWNLOAD_COLUMNS.map { |col| col[:header] }
    @header = headers.join(',')
  end

  def show_sparql_explanation(preferences)
    explanation = ExplainCommand.new(preferences).load_explanation
    redirect_to "/app/hpi/qonsole?q=#{URI.encode_www_form_component(explanation[:sparql])}"
  end

  def prepare_data_download(preferences)
    template = choose_template(preferences)

    if data_download?
      @query_command = QueryCommand.new(preferences)
      @query_command.load_query_results(limit: :all, download: true, max: MAX_DOWNLOAD_RESULTS)

      template = 'ppd/error' unless @query_command.success?
    end

    render template
  end

  def choose_template(preferences)
    template = 'show'

    if preferences.param('header')
      template = 'show_with_header'
      create_download_header
    end

    @preferences = preferences
    template
  end
end
