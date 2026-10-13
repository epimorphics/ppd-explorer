# frozen_string_literal: true

# :nodoc:
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

  # Temporarily disable csrf for load testing.
  # Was: protect_from_forgery with: :exception
  protect_from_forgery with: :null_session

  before_action :set_phase
  before_action :change_default_caching_policy

  def set_phase
    @phase = :released
  end

  # * Set cache control headers for HMLR apps to be public and cacheable
  # * Price Paid Data uses a time limit of 5 minutes (300 seconds)
  # Sets the default `Cache-Control` header for all requests,
  # unless overridden in the action
  def change_default_caching_policy
    expires_in 5.minutes, public: true, must_revalidate: true if Rails.env.production?
  end
end
