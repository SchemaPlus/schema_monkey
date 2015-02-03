module SchemaMonkey::Core
  module ActiveRecord
    module ConnectionAdapters
      module PostgresqlAdapter

        def self.included(base)
          base.class_eval do
            alias_method_chain :exec_cache, :schema_monkey
            alias_method_chain :indexes, :schema_monkey
          end
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::SchemaStatements, SchemaMonkey::Core::ActiveRecord::ConnectionAdapters::SchemaStatements::Reference
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaStatements, SchemaMonkey::Core::ActiveRecord::ConnectionAdapters::SchemaStatements::Column
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaStatements, SchemaMonkey::Core::ActiveRecord::ConnectionAdapters::SchemaStatements::Index
        end

        def exec_cache_with_schema_monkey(sql, name, binds)
          SchemaMonkey::Middleware::Query::ExecCache.start(connection: self, sql: sql, name: name, binds: binds) { |env|
            env.result = exec_cache_without_schema_monkey(env.sql, env.name, env.binds)
          }.result
        end

        def indexes_with_schema_monkey(table_name, query_name=nil)
          SchemaMonkey::Middleware::Query::Indexes.start(connection: self, table_name: table_name, query_name: query_name, index_definitions: []) { |env|
            env.index_definitions += indexes_without_schema_monkey env.table_name, env.query_name
          }.index_definitions
        end
      end
    end
  end
end
