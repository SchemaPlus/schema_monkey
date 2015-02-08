module SchemaMonkey
  class Client
    attr_reader :monkey

    def initialize(monkey, mod)
      @monkey = monkey
      @root = mod
      @inserted_middleware = {}
    end

    def insert(dbm: nil)
      insert_modules(dbm: dbm)
      insert_middleware(dbm: dbm)
      @root.insert(dbm: dbm) if @root.respond_to?(:insert) and @root != ::SchemaMonkey
    end

    def insert_modules(dbm: nil)
      # Kernel.warn "--- inserting modules for #{@root}, dbm=#{dbm.inspect}"
      find_modules(:ActiveRecord, dbm: dbm).each do |mod|
        next if mod.is_a? Class
        relative_path = canonicalize_path(mod, :ActiveRecord, dbm)
        next unless base = Module.const_lookup(::ActiveRecord, relative_path)
        # Kernel.warn "inserting #{mod} (dbm=#{dbm})"
        Module.insert base, mod
      end
    end

    def insert_middleware(dbm: nil)
      find_modules(:Middleware, dbm: dbm).each do |mod|
        next if @inserted_middleware[mod]
        relative_path = canonicalize_path(mod, :Middleware, dbm)
        Stack.insert(relative_path, mod) unless relative_path.empty?
        @inserted_middleware[mod] = true
      end
    end

    private

    def canonicalize_path(mod, base, dbm)
      path = mod.to_s.sub(/^#{@root}::#{base}::/, '')
      if dbm
        path = path.split('::').reject(&it =~ /\b#{dbm}\b/i).join('::') # remove /dbm/ from path
        path = path.gsub(/#{dbm}/i, dbm.to_s) # canonicalize case for things like PostgreSQLAdapter
      end
      path
    end

    def find_modules(container, dbm: nil)
      return [] unless (container = Module.const_lookup @root, container)

      if dbm
        accept = /\b#{dbm}/i
        reject = nil
      else
        accept = nil
        reject = /\b(#{DBMS.join('|')})/i
      end

      modules = []
      modules += Module.descendants(container, can_load: accept)
      modules.select!(&it.to_s =~ accept) if accept
      modules.reject!(&it.to_s =~ reject) if reject
      modules
    end

  end
end
