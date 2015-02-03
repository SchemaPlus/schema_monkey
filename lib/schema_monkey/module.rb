module SchemaMonkey
  module Module
    extend self

    def include_once(base, mod)
      base.send(:include, mod) unless base.include? mod
    end

    # ruby 2.* supports mod.const_get("Component::Path") but ruby 1.9.3
    # doesn't.  And neither has an option to return nil rather than raising
    # a NameError
    def const_lookup(mod, name)
      name.to_s.split('::').map(&:to_sym).each do |component|
        begin
          mod = mod.const_get(component, false)
        rescue NameError
          return nil
        end
      end
      mod
    end

    def descendants(mod, opts={})
      opts = opts.keyword_args(can_load: nil)
      consts, auto = mod.constants.group_by{|c| !!mod.autoload?(c)}.values_at(false, true)
      consts ||= []
      consts += auto.select &it.to_s =~ opts.can_load if opts.can_load and auto
      children = consts.map{|c| mod.const_get(c) }.select &it.is_a?(::Module)
      children + children.flat_map {|c| descendants(c, can_load: opts.can_load) }
    end

  end
end
