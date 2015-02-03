module SchemaMonkey
  class Client
    attr_reader :monkey

    def initialize(monkey, mod)
      @monkey = monkey
      @root = mod
      @inserted = {}
    end

    def insert(opts={})
      opts = opts.keyword_args(:dbm)
      include_modules(dbm: opts.dbm)
      insert_middleware(dbm: opts.dbm)
      @root.insert() if @root.respond_to?(:insert) and @root != ::SchemaMonkey
    end

    def include_modules(opts={})
      opts = opts.keyword_args(:dbm)
      # Kernel.warn "--- include modules for #{@root}, dbm=#{opts.dbm.inspect}"
      find_modules(:ActiveRecord, dbm: opts.dbm).each do |mod|
        next if mod.is_a? Class
        component = mod.to_s.sub(/^#{@root}::ActiveRecord::/, '')
        component = component.gsub(/#{opts.dbm}/i, opts.dbm.to_s) if opts.dbm # canonicalize case
        next unless base = Module.const_lookup(::ActiveRecord, component)
        # Kernel.warn "including #{mod} (dbm=#{opts.dbm})"
        Module.include_once base, mod
      end
    end

    def insert_middleware(opts={})
      opts = opts.keyword_args(:dbm)
      find_modules(:Middleware, dbm: opts.dbm).each do |mod|
        next if @inserted[mod]

        stack_path = mod.to_s.sub(/^#{@root}::Middleware::/, '')
        stack_path = stack_path.split('::').reject(&it =~/\b#{opts.dbm}\b/i).join('::') if opts.dbm

        monkey.insert_middleware_hook(mod, stack_path: stack_path) unless stack_path.empty?

        @inserted[mod] = true
      end
    end

    private

    def find_modules(container, opts={})
      opts = opts.keyword_args(dbm: nil)
      return [] unless (container = Module.const_lookup @root, container)

      if opts.dbm
        accept = /\b#{opts.dbm}/i
        reject = nil
      else
        accept = nil
        reject = /\b(#{SchemaMonkey::DBMS.join('|')})/i
      end

      modules = []
      modules += Module.descendants(container, can_load: accept)
      modules.select!(&it.to_s =~ accept) if accept
      modules.reject!(&it.to_s =~ reject) if reject
      modules
    end

  end
end
