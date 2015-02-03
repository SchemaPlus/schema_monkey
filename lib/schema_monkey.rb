require_relative "schema_monkey/core"
require_relative "schema_monkey/tool"

# 
# Middleware contents will be created dynamically
#
module SchemaMonkey
  module Middleware
  end
end

#
# Wrap public API of SchemaMonkey::Tool
#
module SchemaMonkey
  def self.register(mod)
    Tool::register(mod)
  end

  def self.insert(opts={})
    Tool::insert(opts)
  end

  def self.include_once(*args)
    Tool::Module.include_once(*args)
  end

  module Rake
    def self.insert(*args)
      Tool::Rake::insert(*args)
    end
  end

  MiddlewareError = Tool::MiddlewareError
end

#
# Register Core extensions
#
SchemaMonkey::Tool.register(SchemaMonkey::Core)
