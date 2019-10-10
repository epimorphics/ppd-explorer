# frozen_string_literal: true

require 'test_helper'
require 'csv'

# Integration tests on the controller that downloads CSVs
class PpdDataControllerTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  describe 'PpdDataController' do
    let(:base_params) do
      {
        'et': ['lrcommon:freehold', 'lrcommon:leasehold'],
        'limit': 100,
        'min_date': '1 January 2016',
        'max_date': '31 January 2016',
        'nb': [true, false],
        'ptype': ['lrcommon:detached', 'lrcommon:semi-detached', 'lrcommon:terraced',
                  'lrcommon:flat-maisonette', 'lrcommon:otherPropertyType'],
        'tc': ['ppd:standardPricePaidTransaction', 'ppd:additionalPricePaidTransaction'],
        'town': 'glastonbury'
      }
    end

    it 'should load a basic CSV' do
      VCR.use_cassette('ppd_data_1') do
        DownloadHelpers.clear_downloads
        visit(ppd_data_path(base_params))
        click_on 'get all results as CSV'
        sleep 3.seconds
        page.save_screenshot('debug-screenshot.png', full: true)

        Rails.logger.debug "download_file #{DownloadHelpers.download}"
        download_file = File.new(DownloadHelpers.download)
        assert File.exist?(download_file)
        csv = CSV.read(download_file)
        _(csv).must_be_kind_of Array
        _(csv.first).must_be_kind_of Array
        _(csv.length).must_be :>, 10
      end
    end

    it 'should load a CSV with headers' do
      VCR.use_cassette('ppd_data_2') do
        DownloadHelpers.clear_downloads
        visit(ppd_data_path(base_params))
        click_on 'get all results as CSV with headers'
        sleep 3.seconds

        download_file = File.new(DownloadHelpers.download)
        assert File.exist?(download_file)
        csv = CSV.read(download_file)
        _(csv).must_be_kind_of Array
        _(csv.first).must_be_kind_of Array
        _(csv.length).must_be :>, 10

        headers = csv.first
        _(headers.first).must_equal 'unique_id'
      end
    end

    it 'should load a CSV that is large enough to trigger the big-file download behaviour' do
      VCR.use_cassette('ppd_data_3') do
        DownloadHelpers.clear_downloads
        until_december_params = base_params.merge(
          min_date: '1 January 2014',
          max_date: '31 December 2017'
        )
        visit(ppd_data_path(until_december_params))
        click_on 'get all results as CSV'
        sleep 4.seconds

        download_file = File.new(DownloadHelpers.download)
        csv = CSV.read(download_file)
        _(csv).must_be_kind_of Array
        _(csv.first).must_be_kind_of Array
        _(csv.length).must_be :>, 1000
      end
    end
  end
end
