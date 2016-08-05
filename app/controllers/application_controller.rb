class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_phase
  def set_phase
    Rails.logger.debug( "setting phase")
    @phase = :released
  end

  unless Rails.application.config.consider_all_requests_local
    rescue_from ActionController::RoutingError, :with => :render_404
    rescue_from ActionController::InvalidCrossOriginRequest, :with => :render_403
    rescue_from Exception, with: :render_exception
  end

  def render_exception( e )
    if e.instance_of? ArgumentError
      render_error( 400 )
    else
      Rails.logger.warn "No explicit error page for exception #{e} - #{e.class.name}"
      render_error( 500 )
    end
  end

  def render_404( e = nil )
    render_error( 404 )
  end

  def render_403( e = nil )
    render_error( 403 )
  end

  def render_error( status )
    Rails.logger.info "render_error #{status} #{request.inspect}"
    self.response_body = nil

    respond_to do |format|
      format.html { render( layout: false,
                            file: Rails.root.join( 'public', 'landing', status.to_s ),
                            status: status ) }
      format.all { render nothing: true, status: status }
    end
  end

end
