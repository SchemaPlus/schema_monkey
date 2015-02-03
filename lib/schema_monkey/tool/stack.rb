module SchemaMonkey::Tool
  class Stack
    def initialize(opts={})
      opts = opts.keyword_args(module: :required, env: :required)
      @module = opts.module
      @env_class = @module.const_set "Env", KeyStruct[*opts.env]
      @hooks = []
    end

    def self.is_hook?(mod)
      return true if (mod.instance_methods & [:before, :around, :after, :implementation]).any?
      return true if Module.const_lookup mod, "ENV"
      false
    end

    def append(mod)
      hook = Hook.new(self, mod)
      @hooks.last._next = hook if @hooks.any?
      @hooks << hook
    end

    def start(env_opts, &implementation)
      env = @env_class.new(env_opts)
      @implementation = implementation

      @hooks.each do |hook|
        hook.before env if hook.respond_to? :before
      end

      @hooks.first._call(env)

      @hooks.each do |hook|
        hook.after env if hook.respond_to? :after
      end

      env
    end

    def call_implementation(env)
      if hook = @hooks.select(&it.respond_to?(:implementation)).last
        hook.implementation(env)
      elsif @implementation
        @implementation.call env
      else
        raise MiddlewareError, "No implementation for middleware stack #{@module}"
      end
    end

    class Hook
      attr_accessor :_next

      def initialize(stack, mod)
        @stack = stack
        singleton_class.send :include, mod
      end

      def _call(env)
        if respond_to? :around
          around(env) { |env|
            _continue env
          }
        else
          _continue env
        end
      end

      def _continue(env)
        if self._next
          self._next._call(env)
        else
          @stack.call_implementation(env)
        end
      end
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
