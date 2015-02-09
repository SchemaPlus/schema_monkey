module SchemaMonkey
  module ActiveRecord
    module ConnectionAdapters
      module AbstractAdapter
        def initialize(*args)
          super
          dbm = case adapter_name
                when /^MySQL/i                 then :Mysql
                when 'PostgreSQL', 'PostGIS'   then :PostgreSQL
                when 'SQLite'                  then :SQLite3
                end
          SchemaMonkey.insert(dbm: dbm)
        end
      end
    end

    def self.insert(relative_path, mod)
      class_methods = relative_path.sub!(/::ClassMethods$/, '')
      base = Module.const_lookup(::ActiveRecord, relative_path)
      raise InsertionError, "No module ActiveRecord::#{relative_path} to insert #{mod}" unless base
      Module.insert (class_methods ? base.singleton_class : base), mod
      mod.extended base if class_methods and mod.respond_to? :extended
    end
  end
end
