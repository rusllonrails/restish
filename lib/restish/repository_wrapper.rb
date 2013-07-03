require 'restish/repository'

module Restish
  module RepositoryWrapper

    def self.extended(base)
      unless base.ancestors.include?(Restish::Model)
        raise TypeError.new('Only Restish::Model can extend RepositoryWrapper')
      end
    end

    def method_missing(method, *args)
      repository.send(method, *args)
    end

    def repository
      Repository.for(self)
    end

  end
end
