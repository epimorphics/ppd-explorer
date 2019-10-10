# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
  add_filter '/config/'
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'

require 'minitest/rails'

require 'mocha/minitest'
require 'json_expressions/minitest'
require 'download_helpers'

require 'capybara/minitest'
require 'capybara/minitest/spec'
require 'capybara/rails'
require 'selenium/webdriver'

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

## Capybara/Selenium configuration

# Register a driver for visible Chrome using Selenium
Capybara.register_driver :chrome do |app|
  profile = Selenium::WebDriver::Chrome::Profile.new
  profile['download.default_directory'] = DownloadHelpers::PATH.to_s
  profile['download.prompt_for_download'] = false

  Capybara::Selenium::Driver.new(app, browser: :chrome, profile: profile)
end

# Register a driver for headless Chrome using Selenium
# Needs extra options to cope with file-downloading in headless Chrome. Taken
# from https://bugs.chromium.org/p/chromium/issues/detail?id=696481#c89
Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new

  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-gpu')
  options.add_argument('--disable-popup-blocking')

  options.add_preference(:download, directory_upgrade: true,
                                    prompt_for_download: false,
                                    default_directory: DownloadHelpers::PATH.to_s)

  options.add_preference(:browser, set_download_behavior: { behavior: 'allow' })

  driver = Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)

  bridge = driver.browser.send(:bridge)
  path = "/session/#{bridge.session_id}/chromium/send_command"

  bridge.http.call(:post, path, cmd: 'Page.setDownloadBehavior',
                                params: {
                                  behavior: 'allow',
                                  downloadPath: DownloadHelpers::PATH.to_s
                                })

  driver
end

Capybara.register_driver :rack_test do |app|
  Capybara::RackTest::Driver.new(app, headers: { 'HTTP_USER_AGENT' => 'Capybara' })
end

# To see the Chrome window while tests are running, set this var to true
see_visible_window_while_test_run = ENV['TEST_BROWSER_VISIBLE']

# Set Capybara to use Chrome via Selenium
driver = see_visible_window_while_test_run ? :chrome : :headless_chrome
Capybara.default_driver    = driver
Capybara.javascript_driver = driver

# VCR Setup
VCR.configure do |config|
  config.cassette_library_dir = 'test/fixtures/vcr_cassettes'
  config.hook_into(:faraday)
  # config.ignore_localhost = true

  # re-record every 7 days, but only if we're running in development not CI
  c.default_cassette_options = { re_record_interval: 7.days } if Rails.env.development?
end
