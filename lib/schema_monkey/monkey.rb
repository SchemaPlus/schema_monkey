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
      opts = opts.keyword_args(group_name: :required, stack_name: :required)

      group = Module.const_lookup Middleware, opts.group_name
      stack = Module.const_lookup(group, opts.stack_name) if group
      env = Module.const_lookup mod, "ENV"

      case
      when stack && env
        raise MiddlewareError, "#{mod}::ENV: stack '#{group}::#{stack}' is already defined"
      when !stack && !env
        raise MiddlewareError, "#{mod}: No stack '#{group}::#{stack}' defined"
      when !stack && env
        group = Middleware.const_set opts.group_name, ::Module.new unless group
        stack = group.const_set opts.stack_name, ::Module.new unless stack
        stack.send :extend, Stack::StartMethod
        stack.send :stack=, Stack.new(name: stack.to_s, env: env)
      end

      stack.stack.append(mod)
    end

  end
end
