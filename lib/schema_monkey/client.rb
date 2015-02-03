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
      find_modules(:ActiveRecord, dbm: opts.dbm).each do |mod|
        next if mod.is_a? Class
        component = mod.to_s.sub(/^#{@root}::ActiveRecord::/, '')
        component = component.gsub(/#{opts.dbm}/i, opts.dbm.to_s) if opts.dbm # canonicalize case
        next unless base = Module.const_lookup(::ActiveRecord, component)
        # Kernel.warn "including #{mod}"
        Module.include_once base, mod
      end
    end

    def insert_middleware(opts={})
      opts = opts.keyword_args(:dbm)
      find_modules(:Middleware, dbm: opts.dbm).each do |mod|
        next if @inserted[mod]


        stackpath = mod.to_s.sub(/^#{@root}::Middleware::/, '').to_s.split('::')
        stackpath.reject!(&it =~ /^#{opts.dbm}$/i) if opts.dbm

        if stackpath.length > 2
          raise MiddlewareError, "Improper middleware module hierarchy #{mod.to_s}: too many levels"
        end

        group, stack = stackpath
        monkey.insert_middleware_hook(mod, group_name: group, stack_name: stack) if stack

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
