require 'active_model/naming'
require 'active_model/dirty'
require 'hashie/mash'
require 'restish/repository_wrapper'
require 'restish/errors'

module Restish
  # This is the base class for all models.
  class Model < Hashie::Mash
    extend ActiveModel::Naming
    include ActiveModel::Dirty

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
      @errors = Errors.new(self)
      @_repository = Repository.for(self.class)
    end

    # Class methods

    # Callback invoked whenever a subclass is created.
    #
    # Tries to resolve an appropriate repository class and extends it into the
    # subclass.
    def self.inherited(base)
      base.extend RepositoryWrapper
    end

    # TODO Write docs.
    def self.attributes(*attrs)
      if attrs.empty?
        return const_get('ATTRIBUTES') || []
      end

      const_set('ATTRIBUTES', attrs)

      define_attribute_methods attrs
      attrs.each do |attr|
        define_method(attr) do
          self[attr]
        end

        define_method("#{attr}=") do |value|
          send("#{attr}_will_change!") unless value == self[attr]
          self[attr] = value
        end
      end
    end

    # Instance methods

    # Saves a resource, currently only creating new records by a +POST+
    # request. Delegates to an instance of +Restish::Repository+.
    # @see Restish::Repository#save
    # @return [Boolean]
    def save
      @_repository.save(self)
    end

    # Updates a resource, making a +PUT+ request. Delegates to an
    # instance of {Restish::Repository}.
    # @see Restish::Repository#update
    def update_attributes(attrs = {})
      merge!(attrs)
      @_repository.save(self)
    end

    # Is the record persisted? This methods is required by ActiveModel.
    #
    # @return [true, false]
    def persisted?
      self[:id].present?
    end

  end
end
