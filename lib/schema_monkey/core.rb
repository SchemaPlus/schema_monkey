module SchemaMonkey
  module Core
    module ActiveRecord
      module ConnectionAdapters
        autoload :PostgresqlAdapter, 'schema_monkey/core/active_record/connection_adapters/postgresql_adapter'
        autoload :Mysql2Adapter, 'schema_monkey/core/active_record/connection_adapters/mysql2_adapter'
        autoload :Sqlite3Adapter, 'schema_monkey/core/active_record/connection_adapters/sqlite3_adapter'
      end
    end
  end
end

require_relative "core/active_record/base"
require_relative "core/active_record/connection_adapters/abstract_adapter"
require_relative "core/active_record/connection_adapters/table_definition"
require_relative 'core/active_record/connection_adapters/schema_statements'
require_relative 'core/active_record/migration/command_recorder'
require_relative 'core/active_record/schema_dumper'
require_relative "core/middleware"
