module SchemaMonkey
  module Stack
    def self.insert(path, mod)
      env = Module.const_lookup(mod, "Env") || Module.const_lookup(mod, "ENV")
      return unless env or Modware.is_middleware?(mod)
      stack_holder = env ? create(path, env) : get(path)
      stack_holder.stack.add(mod)
    rescue MiddlewareError => err
      raise MiddlewareError, "#{mod}: #{err.message}"
    end

    private

    def self.create(path, env)
      if mod = get(path, err: false)
        raise MiddlewareError, "stack #{mod} is already defined"
      end
      Module.mkpath(SchemaMonkey::Middleware, path).tap { |mod|
        mod.send :extend, Stack::StackHolder
        mod.send :stack=, Modware::Stack.new(env: env)
      }
    end

    def self.get(path, err: true)
      mod = Module.const_lookup SchemaMonkey::Middleware, path
      return mod if mod and mod.is_a? Stack::StackHolder
      raise MiddlewareError, "No stack #{SchemaMonkey::Middleware}::#{path}" if err
    end

    module StackHolder
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
