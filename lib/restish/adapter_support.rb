require 'active_support/deprecation'
require 'active_support/core_ext/module'
require 'faraday'
require 'faraday_middleware'
require 'faraday/http_cache'

module Restish
  module AdapterSupport
    # Instance methods

    # Get the adapter with given name.
    #
    # @param [String] name Adapter name.
    # @return [Adapter]
    def adapter(name)
      if Restish.adapters[name]
        Restish.adapters[name]
      else
        initialize_adapter(name).tap do |adapter|
          Restish.adapters[name] = adapter
        end
      end
    end

    protected

    # Initialize new adapter.
    #
    # @param [String] name Adapter name.
    # @return [Adapter]
    def initialize_adapter(name)
      adapter_class = get_adapter_class(name)
      if adapter_class
        connection = if adapter_class.respond_to?(:connection)
                       adapter_class.connection
                     else
                       default_connection
                     end
        adapter_class.new(connection)
      end
    end

    # Get class for given adapter name.
    #
    # @param [String] name Adapter name.
    # @return [Class]
    def get_adapter_class(name)
      begin
        "#{name.to_s.camelize}Adapter".constantize
      rescue NameError => e
        nil
      end
    end

    # Return default connection object for adapters to use.
    #
    # @return [Faraday]
    def default_connection
      @default_connection ||= begin
        url = Restish.default_url
        Faraday.new(url: url) do |faraday|
          faraday.request :json
          faraday.response :json
          faraday.use :instrumentation
          logger = Rails.logger if defined?(Rails)
          faraday.use :http_cache, logger: logger
          faraday.adapter Faraday.default_adapter
        end
      end
    end
  end
end

