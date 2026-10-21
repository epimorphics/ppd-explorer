# frozen_string_literal: true

# The Data Services API answered with any other error, such as a 404 from an
# endpoint that should exist, or a body that could not be parsed. An upstream or
# deployment fault (a broken API release, a wrong API_SERVICE_URL), so a 502.
class ApiBadResponseError < ApiError
end
