require 'restish/adapter_support'

module Restish
  class Repository
    include AdapterSupport

    mattr_accessor :repositories

    self.repositories = []

    # Class methods:

    # Clear memoized values cache from all known repositories.
    def self.clear_cache
      repositories.each &:clear_cache
    end

    # Callback invoked whenever Repository is extended into a class.
    def self.extended(base)
      repositories.push base
    end

    # TODO Write docs.
    def self.for(model)
      "#{model.to_s.classify}Repository".constantize.new
    rescue NameError
      Repository.new
    end


    # Instance methods:

    # Clears memoized values from repository.
    def clear_cache
      @all = nil
    end

    # Return all models.
    #
    # @return [Array]
    def all(options = {})
      if options.present?
        adapter(model_class).all(options)
      else
        @all ||= adapter(model_class).all
      end
    end

    # Find the record with given ID.
    #
    # @param [String,Integer] id Model ID
    # @return [Model]
    def find(id, options = {})
      if model = find_locally(id)
        model
      else
        adapter(model_class).find(id, options)
      end
    end

    # Find the record with given ID.
    #
    # @param [String,Integer] id Model ID
    # @return [Model]
    def find_locally(id)
      if @all.present?
        @all.find { |model| model.id == id }
      end
    end

    # Creates or updates a +model+ by making +POST+ (or +PUT+ in case of
    # update) request to a remote
    # service, and handles errors emitted by {Restish::Adapter}.
    # @see Restish::Adapter
    #
    # @param [Model] model An instance to save.
    # @return [Boolean] +true+ - success, +false+ - error.
    def save(model)
      if model.persisted?
        return true if !model.changed?
        update(model)
      else 
        # Save
        handle_errors(model) do
          model.merge!(adapter(model_class).create(model)) unless model.persisted?
        end
      end
    end

    # Filter all records with query.
    #
    # @param [Hash] query
    # @param [Array]
    def filter(query)
      query.inject(all) do |matching, (key, val)|
        matching.select { |category| category[key] == val }
      end
    end

    def post(id, action)
      adapter(model_class).post(id, action)
    end

    protected
    
    # Updates a +model+ by making +PUT+ request to a remote service, and
    # handles errors emitted by {Restish::Adapter}
    # @see Restish::Adapter
    #
    # @param [Model] model An instance to update.
    # @return [Boolean] +true+ - success, +false+ - error.
    def update(model)
      handle_errors(model) do
        model.merge!(adapter(model_class).update(model))
      end
    end

    def model_class
      model_name = self.class.name[/^(.*)Repository$/, 1]
      (model_name || name).underscore
    end

    # Updates model.errors if Restish::Adapter::UnprocessableEntityError
    # is raised.
    # 
    # @param [Model] model Model to populate.
    # @return [Boolean]
    def handle_errors(model, &blk)
      blk.call()
      true
    rescue Restish::Adapter::UnprocessableEntityError => e
      model.errors.from_hash(e.errors)
      false
    end

  end
end
