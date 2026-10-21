# frozen_string_literal: true

# The Data Services API rejected the query ppd built (400 or 422). A bug in this
# application, so it is a 500: reported to Sentry and counted as an internal error.
class ApiQueryRejectedError < ApiError
end
