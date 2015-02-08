module SchemaMonkey
  class Client
    attr_reader :monkey

    def initialize(monkey, mod)
      @monkey = monkey
      @root = mod
      @inserted = {}
    end

    def insert(dbm: nil)
      include_modules(dbm: dbm)
      insert_middleware(dbm: dbm)
      @root.insert(dbm: dbm) if @root.respond_to?(:insert) and @root != ::SchemaMonkey
    end

    def include_modules(dbm: nil)
      # Kernel.warn "--- include modules for #{@root}, dbm=#{dbm.inspect}"
      find_modules(:ActiveRecord, dbm: dbm).each do |mod|
        next if mod.is_a? Class
        component = mod.to_s.sub(/^#{@root}::ActiveRecord::/, '')
        component = component.gsub(/#{dbm}/i, dbm.to_s) if dbm # canonicalize case
        next unless base = Module.const_lookup(::ActiveRecord, component)
        # Kernel.warn "including #{mod} (dbm=#{dbm})"
        Module.include_once base, mod
      end
    end

    def insert_middleware(dbm: nil)
      find_modules(:Middleware, dbm: dbm).each do |mod|
        next if @inserted[mod]

        stack_path = mod.to_s.sub(/^#{@root}::Middleware::/, '')
        stack_path = stack_path.split('::').reject(&it =~/\b#{dbm}\b/i).join('::') if dbm

        monkey.insert_middleware_hook(mod, stack_path: stack_path) unless stack_path.empty?

        @inserted[mod] = true
      end
    end

    private

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
