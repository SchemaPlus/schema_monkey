module SchemaMonkey
  class Stack
    def initialize(opts={})
      opts = opts.keyword_args(name: :required, env: :required)
      @name = opts.name
      @env_class = KeyStruct[*opts.env]
      @hooks = []
    end

    def self.is_hook?(mod)
      return true if (mod.instance_methods & [:before, :around, :after, :implementation]).any?
      return true if Module.const_lookup mod, "ENV"
      false
    end

    def append(mod)
      hook = Hook.new(self, mod)
      @hooks.last.next = hook if @hooks.any?
      @hooks << hook
    end

    def start(env_opts, &implementation)
      env = @env_class.new(env_opts)
      @implementation = implementation

      @hooks.each do |hook|
        hook.before env if hook.respond_to? :before
      end

      @hooks.first.call(env) if @hooks.any?

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
        raise MiddlewareError, "No implementation for middleware stack #{@name}"
      end
    end

    class Hook
      attr_accessor :next

      def initialize(stack, mod)
        @stack = stack
        singleton_class.send :include, mod
      end

      def call(env)
        if respond_to? :around
          around(env) { |env|
            continue env
          }
        else
          continue env
        end
      end

      def continue(env)
        if self.next
          self.next.call(env)
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
