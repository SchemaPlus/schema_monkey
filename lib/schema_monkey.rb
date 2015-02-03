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

  module Middleware
    # contents will be created dynamically
  end

  DBMS = [:PostgreSQL, :Mysql, :SQLite3]

  def self.register(mod)
    monkey.register(mod)
  end

  def self.insert(opts={})
    monkey.insert(opts)
  end

  def self.include_once(*args)
    Module.include_once(*args)
  end
  
  private

  def self.monkey
    @monkey ||= Monkey.new.tap {|monkey| monkey.register SchemaMonkey::Core}
  end

  def self.reset_for_rspec
    @monkey = nil
    remove_const :Middleware
    const_set :Middleware, ::Module.new
  end

end
