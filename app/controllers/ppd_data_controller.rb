# frozen_string_literal: true

# Controller for downloading data
class PpdDataController < ApplicationController
  include DsapiTurtleFormatter
  MAX_DOWNLOAD_RESULTS = 1_000_000
  LARGE_RESULTSET_THRESHOLD = 1

  rescue_from MalformedSearchError, with: :render_malformed_search_error

  def show
    preferences = UserPreferences.new(params)

    if explanation?
      show_sparql_explanation(preferences)
    else
      download_data(preferences)
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
    csv_data_download? || ttl_data_download?
  end

  def csv_data_download?
    request.format == Mime::Type.lookup_by_extension(:csv)
  end

  def ttl_data_download?
    request.format == Mime::Type.lookup_by_extension(:ttl)
  end

  def create_download_header
    headers = DownloadRecord::DOWNLOAD_COLUMNS.map { |col| col[:header] }
    @header = headers.join(',')
  end

  def show_sparql_explanation(preferences)
    explanation = ExplainCommand.new(preferences).load_explanation
    redirect_to "/app/hpi/qonsole?q=#{URI.encode_www_form_component(explanation[:sparql])}"
  end

  def download_data(preferences)
    template = choose_template(preferences)
    template = prepare_data_download(preferences, template) if data_download?

    return unless template
    @preferences = preferences
    render template
  end

  def choose_template(preferences)
    template = 'show'

    if preferences.param('header')
      template = 'show_with_header'
      create_download_header
    end

    template
  end

  def prepare_data_download(preferences, template)
    query_command = QueryCommand.new(preferences)
    query_command.load_query_results(limit: :all, download: true, max: MAX_DOWNLOAD_RESULTS)

    if large_csv_resultset?(query_command)
      render_csv_file(query_command)
      nil
    else
      @query_command = query_command
      query_command.success? ? template : 'ppd/error'
    end
  end

  def large_csv_resultset?(query_command)
    csv_data_download? && query_command.size > LARGE_RESULTSET_THRESHOLD
  end

  def render_csv_file(query_command)
    csv_file = write_csv_file(query_command)
    send_file(csv_file, filename: 'ppd---data.csv', type: 'text/csv')
  ensure
    csv_file&.close
  end

  def write_csv_file(query_command)
    file = Tempfile.new(%w[ppd_data csv])
    Rails.logger.debug "Tempfile is #{file.path}"
    file.open('w+') do |f|
      f << @headers if @headers
      write_csv_rows(query_command, f)
    end

    file.rewind
    file
  end

  def write_csv_rows(query_command, file)
    query_command.search_results.each_transaction do |sr|
      row = []
      DownloadRecord.new(sr).each_column { |csv_value| row << csv_value }
      file << row.join(',')
    end
  end
end
