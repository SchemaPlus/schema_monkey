module SchemaMonkey
  module Stack
    def self.insert(path, mod)
      env = Module.const_lookup(mod, "Env") || Module.const_lookup(mod, "ENV")
      return unless env or Modware.is_middleware?(mod)
      stack = env ? create(path, env) : get(path)
      stack.stack.add(mod)
    rescue MiddlewareError => err
      raise MiddlewareError, "#{mod}: #{err.message}"
    end

    private

    def self.create(path, env)
      if stack = get(path, err: false)
        raise MiddlewareError, "stack #{stack} is already defined"
      end
      Module.mkpath(SchemaMonkey::Middleware, path).tap { |stack|
        stack.send :extend, Stack::StartMethod
        stack.send :stack=, Modware::Stack.new(env: env)
      }
    end

    def self.get(path, err: true)
      stack = Module.const_lookup SchemaMonkey::Middleware, path
      return stack if stack
      raise MiddlewareError, "No stack #{SchemaMonkey::Middleware}::#{path}" if err
    end

    module StartMethod
      attr_reader :stack

      def start(env, &block)
        stack.start(env, &block)
      end

      private

      def stack=(stack)
        @stack = stack
      end
    end
  end
end
