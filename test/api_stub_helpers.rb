# frozen_string_literal: true

# Helpers for integration tests that follow a request through the real
# data_services_api gem, with only its HTTP connection replaced
module ApiStubHelpers
  # Have the gem talk to a connection that answers every request as the block does.
  # The block may take the request's Faraday::Env, to see what was sent. The
  # response middleware is the gem's own (data_services_api 2.1), in the same
  # order, so a body that isn't JSON fails to parse as it would in production.
  def stub_api_connection(&)
    stubs = Faraday::Adapter::Test::Stubs.new { |stub| stub.get('/landregistry/id/ppd', &) }
    url = "#{Rails.application.config.api_service_url}/landregistry/id/ppd"
    connection = Faraday.new(url: url) do |config|
      config.response :json, content_type: [], preserve_raw: true
      config.response :raise_error
      config.adapter :test, stubs
    end
    DataServicesApi::Service.any_instance.stubs(:create_http_connection).returns(connection)
  end

  # The payloads of the internal error events emitted while the block runs
  def internal_error_events(&)
    events = []
    callback = ->(*, payload) { events << payload }
    ActiveSupport::Notifications.subscribed(callback, 'internal_error.application', &)
    events
  end
end
