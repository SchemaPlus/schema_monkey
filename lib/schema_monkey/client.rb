module SchemaMonkey
  class Client

    def initialize(mod)
      @root = mod
      @inserted_middleware = {}
    end

    def insert(dbm: nil)
      insert_active_record(dbm: dbm)
      insert_middleware(dbm: dbm)
    end

    private

    def insert_active_record(dbm: nil)
      # Kernel.warn "--- inserting active_record for #{@root}, dbm=#{dbm.inspect}"
      find_modules(:ActiveRecord, dbm: dbm).each do |mod|
        relative_path = canonicalize_path(mod, :ActiveRecord, dbm)
        ActiveRecord.insert(relative_path, mod)
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

    def canonicalize_path(mod, base, dbm)
      path = mod.to_s.sub(/^#{@root}::#{base}::/, '')
      if dbm
        path = path.split('::')
        if (i = path.find_index(&it =~ /\b#{dbm}\b/i)) # delete first occurence 
          path.delete_at i
        end
        path = path.join('::').gsub(/#{dbm}/i, dbm.to_s) # canonicalize case for things like PostgreSQLAdapter
      end
      path
    end

    def find_modules(container, dbm: nil)
      return [] unless (container = Module.const_lookup @root, container)

      if dbm
        accept = /#{dbm}/i
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
