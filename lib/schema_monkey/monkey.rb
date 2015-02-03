module SchemaMonkey

  # The main manager for the monkey patches.  Singleton instance 
  # created by SchemaMonkey.monkey

  class Monkey

    attr_reader :clients, :stacks

    def initialize
      @clients = []
    end

    def register(mod)
      clients << Client.new(self, mod)
    end

    def insert(opts={})
      opts = opts.keyword_args(:dbm)
      clients.each &it.insert(dbm: opts.dbm)
    end

    def insert_middleware_hook(mod, opts={})
      opts = opts.keyword_args(stack_path: :required)

      return unless Stack.is_hook?(mod)

      stack = Module.const_lookup Middleware, opts.stack_path
      env = Module.const_lookup mod, "ENV"


      case
      when stack && env
        raise MiddlewareError, "#{mod}::ENV: stack #{stack} is already defined"
      when !stack && !env
        raise MiddlewareError, "#{mod}: No stack #{Middleware}::#{opts.stack_path}"
      when !stack && env
        stack = Module.mkpath Middleware, opts.stack_path
        stack.send :extend, Stack::StartMethod
        stack.send :stack=, Stack.new(name: stack.to_s, env: env)
      end

      stack.stack.append(mod)
    end

  end
end
