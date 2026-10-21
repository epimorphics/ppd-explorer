# frozen_string_literal: true

# An error response from the Data Services API, classified by who has to act on it.
# Each subclass is given its status in `rescue_responses` (config/application.rb).
#
# data_services_api raises a DataServicesApi::ServiceException for any error
# response. `DataService#call_api` re-raises it as one of these, keeping it as the
# `cause`, so that the status reflects what went wrong rather than just that the
# API answered with an error.
class ApiError < RuntimeError
  # ppd only calls fixed dataset paths, and user input reaches only the query, so a
  # 400 or 422 means ppd built a query the API rejects: a bug in this application.
  QUERY_REJECTED = [400, 422].freeze

  # The error to raise for the given ServiceException
  def self.for(service_exception)
    status = service_exception.status
    error_class =
      if QUERY_REJECTED.include?(status)
        ApiQueryRejectedError
      elsif status && status >= 500
        ApiUnavailableError
      else
        ApiBadResponseError
      end
    error_class.new(service_exception.message)
  end
end
