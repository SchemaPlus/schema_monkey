module SchemaMonkey::CoreExtensions
  module ActiveRecord
    module ConnectionAdapters
      module PostgresqlAdapter

        def self.prepended(base)
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::SchemaStatements, SchemaMonkey::CoreExtensions::ActiveRecord::ConnectionAdapters::SchemaStatements::Reference
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaStatements, SchemaMonkey::CoreExtensions::ActiveRecord::ConnectionAdapters::SchemaStatements::Column
          SchemaMonkey.include_once ::ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaStatements, SchemaMonkey::CoreExtensions::ActiveRecord::ConnectionAdapters::SchemaStatements::Index
        end

        def exec_cache(sql, name, binds)
          SchemaMonkey::Middleware::Query::ExecCache.start(connection: self, sql: sql, name: name, binds: binds) { |env|
            env.result = super env.sql, env.name, env.binds
          }.result
        end

        def indexes(table_name, query_name=nil)
          SchemaMonkey::Middleware::Query::Indexes.start(connection: self, table_name: table_name, query_name: query_name, index_definitions: []) { |env|
            env.index_definitions += super env.table_name, env.query_name
          }.index_definitions
        end
      end
    end
  end
end
