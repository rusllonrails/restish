require 'active_support/core_ext/object'
require 'active_support/inflector'

module Restish
  class Adapter
    attr_accessor :connection

    # General connection error. Saves +response+ for futher handling.
    class ResponseError < StandardError
      attr_reader :response

      # Creates new instance of +ResponseError+.
      #
      # @param [Faraday::Response] response Data returned from the server.
      # @param [String] message Error message.
      def initialize(response, message = nil)
        @response = response
        @message = message
      end

      def to_s
        m = "Server returned unhandled status #{@response.status}"
        m << ": #{@message}" unless @message.blank?
        m
      end
    end

    # Raised on 422 Unprocessable Entity.
    class UnprocessableEntityError < ResponseError

      # Returns hash of error messages.
      # @return [Hash]
      def errors
        response.body['errors'] || {}
      end
    end

    # Raise on 401 Unauthorized.
    UnauthorizedError = Class.new(ResponseError)

    # Raise on 404 Not Found.
    NotFoundError = Class.new(ResponseError)

    def initialize(connection)
      @connection = connection
    end

    # Fetches and materializes the record instance with the given ID.
    #
    # @param [Fixnum, String] id The record ID
    # @return [Object] The instance of model class
    def find(id, options = {})
      url = options[:url] || url_for(id)
      response = connection.get url
      handle_and_unpack_response(response, 200)
    end

    # Fetches and materializes the collection of records.
    #
    # @param [Fixnum, String] id The record ID
    # @option options [String] :url The url to fetch
    # @return [Array] The array of instances of model class
    def all(options = {})
      url = options[:url] || url_for(:all)
      response = connection.get url
      collection = Collection.new(handle_and_unpack_response(response, 200))
      meta = unpack_meta(response)
      collection.meta_params = meta if meta
      collection
    end

    # Creates the model on the server.
    #
    # @param [Restish::Model] model
    # @return [Restish::Model]
    def create(model)
      response = connection.post url_for(:all), model.to_json
      handle_and_unpack_response(response, 201)
    end

    # Updates existing model on the server.
    #
    # @param [Restish::Model] model Model to update.
    # @return [Restish::Model]
    def update(model)
      response = connection.put url_for(model.id), model.to_json
      handle_and_unpack_response(response, 200)
    end

    def post(id, action)
      response = connection.post url_for("#{id}/#{action}")
      handle_and_unpack_response(response, 201)
    end

    # Figure out the url for given scope.
    #
    # The scope can either be :all if you want the URL for all records or any
    # other word if you want to scope the url further.
    #
    # @param [Symbol,String] scope
    # @return [String] URL
    def url_for(scope)
      url = []
      url.push(prefix) if prefix.present?
      url.push "#{model_class.model_name.collection}"
      url.push(scope) if !scope || scope != :all
      url = url * '/'
      format.present? ? "#{url}.#{format}" : url
    end

    # Prefix for URL. To be implemented in ApplicationAdapter.
    def prefix; end

    # Format for the URL. To be implemented in ApplicationAdapter.
    def format; end

    private

    # Handles given response by unpacking and materializing the models.
    #
    # @param [Response] response Response object
    # @param [Fixnum] handled_status The status code which is considered handled
    # @return [Array<Object>, Object]
    def handle_and_unpack_response(response, handled_status)
      handle_response(response, handled_status) do
        unpack_attributes(response.body) do |attrs|
          materialize_model(attrs)
        end
      end
    end

    # Handles given response by checking the the status code and yielding block
    # if the code is handled. Otherwise throws an exception.
    #
    # @param [Response] response Response object
    # @param [Fixnum] handled_status The status code which is considered handled
    def handle_response(response, handled_status, &block)
      if response.status == handled_status
        block.call(response)
      else
        case response.status
        when 401
          raise UnauthorizedError.new(response)
        when 404
          raise NotFoundError.new(response)
        when 422
          raise UnprocessableEntityError.new(response)
       else
          raise "Server returned unhandled status #{response.status}"
        end
      end
    end

    # Materialize model with given attributes.
    #
    # @param [Hash] model_attributes
    # @param [Object] Materialized model
    def materialize_model(model_attributes)
      model_class.new(model_attributes)
    end

    # Return the model class for adapter.
    #
    # @return [Class]
    def model_class
      model_name = self.class.name[/^(.*)Adapter$/, 1]
      model_name.constantize
    end

    # Unpacks the model attributes from given response body (hash).
    #
    # If collection is found inside the response this methods yields each
    # attributes hash and returns the results of yields in an array. If singular
    # model attributes are found then yields only once and returns the result
    # of the yield directly.
    #
    # @param [Hash] response_body
    # @return [Array, Object]
    def unpack_attributes(response_body, &block)
      demodulized_key = model_class.model_name.to_s.demodulize.underscore
      modulized_key = model_class.model_name.singular
      [demodulized_key, modulized_key].each do |key|
        plural_key = key.pluralize
        singular_key = key.singularize
        if response_body.has_key?(plural_key)
          return response_body[plural_key].map(&block)
        elsif response_body.has_key?(singular_key)
          return block.call(response_body[singular_key])
        end
      end
      raise "Unable to unpack model attributes from #{response_body}!"
    end

    # Unpacks metadata from response body hash.
    #
    # @param [Hash] response
    # @return [Hash]
    def unpack_meta(response)
      response.body['meta'] if response.body.has_key?('meta')
    end

  end
end
