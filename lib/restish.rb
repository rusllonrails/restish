require 'restish/version'
require 'restish/collection'
require 'restish/adapter_support'
require 'restish/adapter'
require 'restish/repository'
require 'restish/model'
require 'restish/middleware/identity_map'

require 'restish/railtie' if defined?(Rails)

module Restish
  # The default URL used by all adapters.
  mattr_accessor :default_url

  # Adapters cache.
  mattr_accessor :adapters

  self.adapters = {}

  # Class methods

  # Clears memoized adapters cache.
  def self.clear_adapters
    @@adapters = {}
  end
end
