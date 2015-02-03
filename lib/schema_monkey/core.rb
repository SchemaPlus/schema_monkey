module SchemaMonkey
  module Core
  end
end

require_relative "core/middleware"
require_relative "core/active_record/base"
require_relative "core/active_record/connection_adapters/abstract_adapter"
require_relative "core/active_record/connection_adapters/table_definition"
require_relative 'core/active_record/connection_adapters/schema_statements'
require_relative 'core/active_record/migration/command_recorder'
require_relative 'core/active_record/schema_dumper'

