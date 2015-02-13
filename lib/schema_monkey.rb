require 'active_record'
require 'active_support/core_ext/string'
require 'its-it'
require 'modware'

require_relative "schema_monkey/active_record"
require_relative "schema_monkey/client"
require_relative "schema_monkey/errors"
require_relative "schema_monkey/module"
require_relative "schema_monkey/monkey"
require_relative "schema_monkey/stack"
require_relative 'schema_monkey/rake'

#
# Middleware contents will be created dynamically
#
module SchemaMonkey
  module Middleware
  end
end

#
#
#
module SchemaMonkey

  DBMS = [:PostgreSQL, :Mysql, :SQLite3]

  def self.register(mod)
    monkey.register(mod)
  end

  def self.insert(opts={})
    monkey.insert(opts)
  end

  private

  def self.monkey
    @monkey ||= Monkey.new
  end

  def self.reset_for_rspec
    @monkey = nil
    self.reset_middleware
  end

  def self.reset_middleware
    SchemaMonkey.send :remove_const, :Middleware
    SchemaMonkey.send :const_set, :Middleware, ::Module.new
  end

end
