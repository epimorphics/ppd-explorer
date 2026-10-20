# frozen_string_literal: true

require 'test_helper'
require 'stringio'

# The framework (epilog_rails) logs each request, not application code. These
# tests fail if a request is logged twice, not at all, or not as plain JSON.
class RequestLoggingTest < ActionDispatch::IntegrationTest
  # Collect everything logged while the block runs, parsed from JSON
  def capture_log
    output = StringIO.new
    sink = ActiveSupport::Logger.new(output).tap do |logger|
      logger.formatter = EpilogRails::JsonFormatter.new
    end
    Rails.logger.broadcast_to(sink)
    yield
    output.string.lines.map { |line| JSON.parse(line) }
  ensure
    Rails.logger.stop_broadcasting_to(sink)
  end

  describe 'Request logging' do
    it 'should log one received and one completed entry for a request' do
      entries = capture_log { get root_path(street: 'harbour road') }

      received = entries.select { |entry| entry['request_status'] == 'received' }
      completed = entries.select { |entry| entry['request_status'] == 'completed' }

      _(received.size).must_equal 1
      _(completed.size).must_equal 1
      _(completed.first['method']).must_equal 'GET'
      _(completed.first['path']).must_equal '/?street=harbour+road'
      _(completed.first['status']).must_equal 200
      _(completed.first['request_time']).must_be_kind_of Float
    end

    it 'should share a request id between the entries for a request' do
      entries = capture_log { get root_path }

      request_ids = entries.pluck('request_id').uniq

      _(request_ids.size).must_equal 1
      _(request_ids.first).wont_be_nil
    end

    it 'should log messages as plain text, not as encoded JSON' do
      entries = capture_log { get root_path }

      _(entries).wont_be_empty
      entries.each do |entry|
        _(entry['message']).must_be_kind_of String
        _(entry['message']).wont_match(/\A\s*[{\[]/)
      end
    end

    it 'should log a failed request once, with the path requested and its status' do
      original_env = render_error_pages

      entries = capture_log { get '/no/such/path' }
      completed = entries.select { |entry| entry['request_status'] == 'completed' }

      _(entries.count { |entry| entry['request_status'] == 'received' }).must_equal 1
      _(completed.size).must_equal 1
      _(completed.first['path']).must_equal '/no/such/path'
      _(completed.first['status']).must_equal 404
    ensure
      Rails.application.env_config.merge!(original_env)
    end

    # The completed entry already records a 404 or 400. Logging the exception as
    # well, at any level, adds an unstructured entry and a backtrace to every trace
    # read at DEBUG.
    it 'should not log a handled error response as an exception' do
      original_env = render_error_pages

      entries = capture_log { get '/no/such/path' }

      _(entries.pluck('message').grep(/RoutingError/)).must_be_empty
      _(entries.pluck('request_status').compact).must_equal %w[received completed]
    ensure
      Rails.application.env_config.merge!(original_env)
    end
  end
end
