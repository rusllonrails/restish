module Restish
  module Middleware
    class IdentityMap
      def initialize(app)
        @app = app
      end

      def call(env)
        Restish::Repository.clear_cache
        Restish.clear_adapters
        status, headers, body = @app.call(env)
        [status, headers, body]
      end
    end
  end
end
