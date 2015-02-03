module SchemaMonkey::CoreExtensions
  module ActiveRecord
    module ConnectionAdapters
      module Sqlite3Adapter

        def self.included(base)
          base.class_eval do
            alias_method_chain :indexes, :schema_monkey
            alias_method_chain :tables, :schema_monkey
          end
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::SchemaStatements, SchemaMonkey::CoreExtensions::ActiveRecord::ConnectionAdapters::SchemaStatements::Column
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::SchemaStatements, SchemaMonkey::CoreExtensions::ActiveRecord::ConnectionAdapters::SchemaStatements::Reference
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::SchemaStatements, SchemaMonkey::CoreExtensions::ActiveRecord::ConnectionAdapters::SchemaStatements::Index
        end

        def indexes_with_schema_monkey(table_name, query_name=nil)
          SchemaMonkey::Middleware::Query::Indexes.start(connection: self, table_name: table_name, query_name: query_name, index_definitions: []) { |env|
            env.index_definitions += indexes_without_schema_monkey env.table_name, env.query_name
          }.index_definitions
        end

        def tables_with_schema_monkey(query_name=nil, table_name=nil)
          SchemaMonkey::Middleware::Query::Tables.start(connection: self, query_name: query_name, table_name: table_name, tables: []) { |env|
            env.tables += tables_without_schema_monkey env.query_name, env.table_name
          }.tables
        end

      end
    end
  end
end


