ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/spec'
require 'capybara/rails'
require 'minitest/capybara'
require 'json_expressions/minitest'
require 'pry'

class AcceptanceTest < Minitest::Unit::TestCase
  include Capybara::DSL
  include Minitest::Capybara::Assertions

  def teardown
    Capybara.reset_session!
    Capybara.use_default_driver
  end
end

class AcceptanceSpec < AcceptanceTest
  extend Minitest::Spec::DSL
end
