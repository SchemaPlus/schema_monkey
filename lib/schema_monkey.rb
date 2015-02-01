require 'hash_keyword_args'
require 'its-it'
require 'key_struct'
require 'middleware'
require 'active_record'
require 'active_support/core_ext/string'

require_relative "schema_monkey/client"
require_relative "schema_monkey/middleware"
require_relative "schema_monkey/module"
require_relative "schema_monkey/active_record/base"
require_relative "schema_monkey/active_record/connection_adapters/abstract_adapter"
require_relative "schema_monkey/active_record/connection_adapters/table_definition"
require_relative 'schema_monkey/active_record/connection_adapters/schema_statements'
require_relative 'schema_monkey/active_record/migration/command_recorder'
require_relative 'schema_monkey/active_record/schema_dumper'
require_relative 'schema_monkey/rake'

module SchemaMonkey
  extend Module

  DBMS = [:PostgreSQL, :Mysql, :SQLite3]

  module ActiveRecord
    module ConnectionAdapters
      autoload :PostgresqlAdapter, 'schema_monkey/active_record/connection_adapters/postgresql_adapter'
      autoload :Mysql2Adapter, 'schema_monkey/active_record/connection_adapters/mysql2_adapter'
      autoload :Sqlite3Adapter, 'schema_monkey/active_record/connection_adapters/sqlite3_adapter'
    end
  end

  def self.register(mod)
    clients << Client.new(mod)
  end

  def self.clients
    @clients ||= [Client.new(self)]
  end

  def self.insert(opts={})
    opts = opts.keyword_args(:dbm)
    clients.each &it.insert(dbm: opts.dbm)
  end

end
