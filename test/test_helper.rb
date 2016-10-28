require 'simplecov'
SimpleCov.start do
  add_filter "/test/"
  add_filter "/config/"
end

ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

require "minitest/rails/capybara"
require "mocha/mini_test"
require 'json_expressions/minitest'

require "minitest/reporters"
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

def params_object(p)
  ActionController::Parameters.new(p)
end
