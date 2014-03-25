# Base class for objects that interact with the data services API
class DataService
  attr_reader :preferences

  def initialize( preferences )
    @preferences = preferences
  end

  # Return a data service object
  def data_service
    DataServicesApi::Service.new
  end

  # Return a dataset wrapper object for the named dataset
  def dataset( ds_name )
    data_service.dataset( ds_name.to_s )
  end

  # Return a new empty query generator
  def base_query
    DataServicesApi::QueryGenerator.new
  end

  # Delegate parameter checking to the user preferences object
  def param( p )
    @preferences.param( p )
  end
end
