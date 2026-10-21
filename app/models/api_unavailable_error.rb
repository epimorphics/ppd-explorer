# frozen_string_literal: true

# The Data Services API is failing (5xx). A 503, as when it cannot be reached:
# nothing for a developer to fix, and ops hear about it from the api_* alerts.
class ApiUnavailableError < ApiError
end
