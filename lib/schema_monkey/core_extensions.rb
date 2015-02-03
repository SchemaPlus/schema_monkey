require 'active_record'
require 'key_struct'

module SchemaMonkey
  module CoreExtensions
    module ActiveRecord
      module ConnectionAdapters
        DIR = Pathname.new(__FILE__).dirname + 'core_extensions/active_record/connection_adapters'
        autoload :PostgresqlAdapter,    DIR + 'postgresql_adapter'
        autoload :Mysql2Adapter,        DIR + 'mysql2_adapter'
        autoload :Sqlite3Adapter,       DIR + 'sqlite3_adapter'
      end
    end
  end
end

require_relative "core_extensions/active_record/base"
require_relative "core_extensions/active_record/connection_adapters/abstract_adapter"
require_relative "core_extensions/active_record/connection_adapters/table_definition"
require_relative 'core_extensions/active_record/connection_adapters/schema_statements'
require_relative 'core_extensions/active_record/migration/command_recorder'
require_relative 'core_extensions/active_record/schema_dumper'
require_relative "core_extensions/middleware"
