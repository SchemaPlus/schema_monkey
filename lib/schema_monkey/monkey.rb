module SchemaMonkey

  # The main manager for the monkey patches.  Singleton instance 
  # created by SchemaMonkey.monkey

  class Monkey

    attr_reader :clients, :stacks

    def initialize
      @clients = []
      @inserted = nil
      @inserted_dbm = nil
    end

    def register(mod)
      client = Client.new(self, mod)
      clients << client
      client.insert if @inserted
      client.insert(@inserted_dbm) if @inserted_dbm
    end

    def insert(dbm: nil)
      @inserted = true
      @inserted_dbm = dbm if dbm
      clients.each &it.insert(dbm: dbm)
    end

    def insert_middleware_hook(mod, stack_path:)

      return unless Modware.is_middleware?(mod) or Module.const_lookup mod, "ENV"

      stack = Module.const_lookup SchemaMonkey::Middleware, stack_path
      env = Module.const_lookup mod, "ENV"

      case
      when stack && env
        raise MiddlewareError, "#{mod}::ENV: stack #{stack} is already defined"
      when !stack && !env
        raise MiddlewareError, "#{mod}: No stack #{SchemaMonkey::Middleware}::#{stack_path}"
      when !stack && env
        stack = Module.mkpath SchemaMonkey::Middleware, stack_path
        stack.send :extend, Stack::StartMethod
        stack.send :stack=, Modware::Stack.new(env: env)
      end

      stack.stack.add(mod)
    end

  end
end
