require 'hash_keyword_args'
require 'its-it'
require 'key_struct'
require 'active_support/core_ext/string'

require_relative "tool/client"
require_relative "tool/errors"
require_relative "tool/module"
require_relative "tool/monkey"
require_relative "tool/stack"
require_relative 'tool/rake'

module SchemaMonkey
  module Tool

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
end
