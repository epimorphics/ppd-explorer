# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
  add_filter '/config/'
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'

require 'minitest/rails/capybara'
require 'mocha/minitest'
require 'json_expressions/minitest'

require 'minitest/reporters'
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

def params_object(params)
  ActionController::Parameters.new(params)
end

module ActiveSupport
  # Set up fixtures and such
  class TestCase
    self.file_fixture_path = 'test/fixtures/files'
  end
end
