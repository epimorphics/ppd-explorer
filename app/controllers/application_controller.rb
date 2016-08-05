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
    elsif e.instance_of? ActionController::InvalidCrossOriginRequest
      render_error( 403 )
    else
      Rails.logger.warn "No explicit error page for exception #{e} - #{e.class.name}"
      render_error( 500 )
    end
  end

  :private

  def render_404( e = nil )
    render_error( 404 )
  end

  def render_403( e = nil )
    render_error( 403 )
  end

  def render_error( status )
    reset_response

    respond_to do |format|
      format.html { render_html_error_page( status ) }
      format.all do
        Rails.logger.info "About to render nothing with status #{status}"
        render nothing: true, status: status
      end
    end
  end

  def render_html_error_page( status )
    Rails.logger.info "render_html_error_page #{status}"
    begin
      render( layout: false,
              file: Rails.root.join( 'public', 'landing', status.to_s ),
              status: status )
    rescue ActionController::InvalidCrossOriginRequest
      reset_response
      render nothing: true, status: 403
    rescue Exception => e
      rails.logger.info "Unexpected error during error handling: #{e.inspect}"
      reset_response
      render nothing: true, status: status
    end
  end

  def reset_response
    self.response_body = nil
  end
end
