require 'hash_keyword_args'
require 'its-it'
require 'key_struct'
require 'active_record'
require 'active_support/core_ext/string'

require_relative "schema_monkey/client"
require_relative "schema_monkey/core"
require_relative "schema_monkey/errors"
require_relative "schema_monkey/module"
require_relative "schema_monkey/monkey"
require_relative "schema_monkey/stack"
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
    monkey.register(mod)
  end

  def self.insert(opts={})
    remove_const :Middleware if defined?(SchemaMonkey::Middleware)
    const_set :Middleware, ::Module.new
    monkey.insert(opts)
  end
  
  private

  def self.monkey
    @monkey ||= Monkey.new.tap {|monkey| monkey.register SchemaMonkey::Core}
  end

  def self.reset_for_rspec
    @monkey = nil
  end

end
