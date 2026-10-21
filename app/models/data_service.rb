# frozen_string_literal: true

# Base class for objects that interact with the data services API
class DataService
  attr_reader :preferences

  def initialize(preferences, compact = false)
    @preferences = preferences
    @compact = compact
  end

  # Return a data service object
  def data_service
    DataServicesApi::Service.new(url: api_service_url)
  end

  # Return a dataset wrapper object for the named dataset
  def dataset(ds_name)
    data_service.dataset(ds_name.to_s)
  end

  # Return a new empty query generator
  def base_query
    q = DataServicesApi::QueryGenerator.new
    compact? ? q.compact_json : q
  end

  # Return true if the service should generate compact JSON
  def compact?
    @compact
  end

  # Delegate parameter checking to the user preferences object
  delegate :param, to: :@preferences

  # Run a call to the Data Services API, re-raising an error response as the
  # ApiError subclass for who has to act on it (see ApiError). Don't log here:
  # ApiRequestLogSubscriber has already logged the call.
  def call_api
    yield
  rescue DataServicesApi::ServiceException => e
    raise ApiError.for(e)
  end

  def api_service_url
    Rails.application.config.api_service_url
  end
end
