# frozen_string_literal: true

require 'test_helper'

# Unit tests on the ApiPrometheusSubscriber class
class ApiPrometheusSubscriberTest < ActiveSupport::TestCase
  delegate :registry, to: Prometheus::Client

  describe 'ApiPrometheusSubscriber' do
    describe '#response' do
      it 'should count the request, its status and its duration' do
        event = stub(payload: { response: stub(status: 200), duration: 42 })

        registry.get(:api_status).expects(:increment).with(labels: { status: '200' })
        registry.get(:api_requests).expects(:increment).with(labels: { result: 'success' })
        registry.get(:api_response_times).expects(:observe).with(42)

        ApiPrometheusSubscriber.new.response(event)
      end
    end

    describe '#connection_failure' do
      it 'should count a failed request, labelled by exception class and not by message' do
        exception = Faraday::ConnectionFailed.new('Failed to open TCP connection to data-api:8080')
        event = stub(payload: { exception: exception })

        registry.get(:api_requests).expects(:increment).with(labels: { result: 'failure' })
        registry.get(:api_connection_failure).expects(:increment)
                .with(labels: { message: 'Faraday::ConnectionFailed' })

        ApiPrometheusSubscriber.new.connection_failure(event)
      end

      it 'should label a timeout by its own class' do
        event = stub(payload: { exception: Faraday::TimeoutError.new('execution expired') })

        registry.get(:api_requests).expects(:increment).with(labels: { result: 'failure' })
        registry.get(:api_connection_failure).expects(:increment)
                .with(labels: { message: 'Faraday::TimeoutError' })

        ApiPrometheusSubscriber.new.connection_failure(event)
      end
    end

    describe '#service_exception' do
      it 'should count a failed request, labelled by response status and not by message' do
        exception = DataServicesApi::ServiceException.new('the server responded with status 503', 503)
        event = stub(payload: { exception: exception })

        registry.get(:api_requests).expects(:increment).with(labels: { result: 'failure' })
        registry.get(:api_service_exception).expects(:increment).with(labels: { message: 'HTTP 503' })

        ApiPrometheusSubscriber.new.service_exception(event)
      end

      it 'should say so when there was no response status' do
        exception = DataServicesApi::ServiceException.new('unexpected token', nil)
        event = stub(payload: { exception: exception })

        registry.get(:api_requests).expects(:increment).with(labels: { result: 'failure' })
        registry.get(:api_service_exception).expects(:increment)
                .with(labels: { message: 'no response status' })

        ApiPrometheusSubscriber.new.service_exception(event)
      end
    end

    # The specs above call the subscriber's methods directly, so they would still
    # pass if `attach_to` named the wrong event prefix. That happened silently in a
    # sibling app when data_services_api 2.0.0 renamed its events from `*.api` to
    # `*.data_services_api`. These fire through the real notification bus, so a
    # future rename fails here.
    describe 'ActiveSupport::Notifications wiring' do
      it 'should count a connection failure when the gem reports one' do
        exception = Faraday::ConnectionFailed.new('Failed to open TCP connection to data-api:8080')

        registry.get(:api_requests).expects(:increment).with(labels: { result: 'failure' })
        registry.get(:api_connection_failure).expects(:increment)
                .with(labels: { message: 'Faraday::ConnectionFailed' })

        ActiveSupport::Notifications.instrument('connection_failure.data_services_api', exception: exception)
      end

      it 'should count a service exception when the gem reports one' do
        exception = DataServicesApi::ServiceException.new('the server responded with status 502', 502)

        registry.get(:api_requests).expects(:increment).with(labels: { result: 'failure' })
        registry.get(:api_service_exception).expects(:increment).with(labels: { message: 'HTTP 502' })

        ActiveSupport::Notifications.instrument('service_exception.data_services_api', exception: exception)
      end
    end
  end
end
