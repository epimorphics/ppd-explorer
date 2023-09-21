# frozen_string_literal: true

# Controller for downloading data
class PpdDataController < ApplicationController
  include DsapiTurtleFormatter
  MAX_DOWNLOAD_RESULTS = 1_000_000

  # Above this number of results in a resultset, we write the CSV to a file first
  LARGE_RESULTSET_THRESHOLD = 1000

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
    # link the error to the actual request id otherwise generate one for this error
    uuid = Thread.current[:request_id] || SecureRandom.uuid

    Rails.logger.error "Malformed search error #{uuid} :: #{exception&.message || 'no message'}"

    render nothing: true, status: :bad_request
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

  def download_header
    DownloadRecord::DOWNLOAD_COLUMNS
      .map { |col| col[:header] }
      .join(',')
  end

  def show_sparql_explanation(preferences)
    explanation = ExplainCommand.new(preferences).load_explanation
    redirect_to "/app/qonsole?q=#{URI.encode_www_form_component(explanation[:sparql])}"
  end

  def download_data(preferences)
    template, headers = choose_template(preferences)
    template = prepare_data_download(preferences, template, headers) if data_download?

    return unless template

    @preferences = preferences
    render template, locals: { headers: headers }
  end

  def choose_template(preferences)
    if preferences.param('header')
      ['show_with_header', download_header]
    else
      ['show', nil]
    end
  end

  def prepare_data_download(preferences, template, headers)
    query_command = QueryCommand.new(preferences)
    query_command.load_query_results(limit: :all, download: true, max: MAX_DOWNLOAD_RESULTS)

    if large_csv_resultset?(query_command)
      render_csv_file(query_command, headers)
      nil
    else
      @query_command = query_command
      query_command.success? ? template : 'ppd/error'
    end
  end

  def large_csv_resultset?(query_command)
    csv_data_download? && query_command.size > LARGE_RESULTSET_THRESHOLD
  end

  def render_csv_file(query_command, headers)
    csv_file = write_csv_file(query_command, headers)
    send_file(csv_file, filename: 'ppd_data.csv', type: 'text/csv')
  ensure
    csv_file&.close
  end

  def write_csv_file(query_command, headers)
    file = Tempfile.new(%w[ppd_data csv])

    File.open(file, 'w') do |f|
      f << headers if headers
      write_csv_rows(query_command, f)
    end

    file
  end

  def write_csv_rows(query_command, file)
    query_command.search_results.each_transaction do |sr|
      DownloadRecord.new(sr).each_column { |csv_value| file << csv_value }
      file << "\n"
    end
  end
end
