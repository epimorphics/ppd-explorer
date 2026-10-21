# frozen_string_literal: true

# Check the Data Services API address at boot, so a bad value stops the app
# starting rather than failing every search.
#
# A malformed URL makes data_services_api raise URI::InvalidURIError before its
# instrumented call, so no API log entry, `api_*` metric or alert names the cause:
# the only symptom is a 500 on every search. A typo in the scheme (`htttp://`) is
# worse, as the request is sent anyway and the mistake goes unnoticed.
#
# An unset value is not checked here: the image build precompiles assets by booting
# Rails in production without API_SERVICE_URL. `entrypoint.sh` refuses to start the
# server without it instead.
module ApiServiceUrl
  SCHEMES = %w[http https].freeze

  def self.validate!(url)
    return if url.blank?

    uri = URI.parse(url)
    raise_invalid(url) unless SCHEMES.include?(uri.scheme) && uri.host.present?
  rescue URI::InvalidURIError
    raise_invalid(url)
  end

  def self.raise_invalid(url)
    raise ArgumentError, "API_SERVICE_URL must be an http or https URL with a host, got #{url.inspect}"
  end
  private_class_method :raise_invalid
end

ApiServiceUrl.validate!(Rails.application.config.api_service_url)
