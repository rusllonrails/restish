require 'active_model/naming'
require 'hashie/mash'
require 'restish/repository'
require 'restish/errors'

module Restish
  # This is the base class for all models.
  class Model < Hashie::Mash
    extend ActiveModel::Naming

    attr_accessor :errors

    # Converts +source_hash+ into +Model+ attributes.
    # @see Hashie::Mash.new
    #
    # @param [Hash] source_hash Hash of model attributes.
    # @param [Object] default Default attribute value.
    # @yield [Hash, String] Gives hash and key name to the block
    #   returning default value.
    #
    # @return [Model]
    def initialize(source_hash = nil, default = nil, &blk)
      super
      @errors = Restish::Errors.new(self)
    end

    # Class methods

    # Callback invoked whenever a subclass is created.
    #
    # Tries to resolve an appropriate repository class and extends it into the
    # subclass.
    def self.inherited(base)
      begin
        repository_class = "#{base}Repository".constantize
        Restish::Repository.repositories.push base
      rescue NameError => e
        repository_class = Restish::Repository
      ensure
        # TODO
        # base.extend repository_class
      end
    end

    # Instance methods

    # Saves a resource, currently only creating new records by a +POST+
    # request. Delegates to an instance of +Restish::Repository+.
    # @see Restish::Repository#save
    def save
      self.class.save(self)
    end

    # Updates a resource, making a +PUT+ request. Delegates to an
    # instance of {Restish::Repository}.
    # @see Restish::Repository#update
    def update_attributes(params = {})
      self.class.update(self, params)
    end

    # Is the record persisted? This methods is required by ActiveModel.
    #
    # @return [true, false]
    def persisted?
      self[:id].present?
    end

  end
end
