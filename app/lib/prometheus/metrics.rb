# frozen_string_literal: true

module Prometheus
  # A shared global register of Prometheus metrics.
  #
  # `Prometheus::Metrics.register_metric`
  # to create a metric for later use
  #
  # `Prometheus::Metrics[name]`
  # to retrieve a metric by name so that it can be updated
  class Metrics
    include Singleton

    attr_reader :registry, :lookup_table

    def initialize
      @registry = Prometheus::Client.registry
      @lookup_table = {}
    end

    def self.register_metric(metric_class, name, docstring, params = {})
      instance.register_metric(metric_class, name, docstring, params)
    end

    def self.[](name)
      instance.lookup_table.fetch(name)
    end

    def register_metric(metric_class, name, docstring, params)
      return if lookup_table.key?(name)

      counter = metric_class.new(name, params.merge(docstring: docstring))

      lookup_table[name] = counter
      registry.register(counter)
    end
  end
end
