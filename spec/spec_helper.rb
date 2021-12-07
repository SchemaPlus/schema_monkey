require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rspec'
require 'rspec/given'
require 'active_record'
require 'schema_monkey'
require 'schema_dev/rspec'

def create_database
  config = SchemaDev::Rspec.db_configuration

  return if config['host'].nil?

  ActiveRecord::Tasks::DatabaseTasks.create(config)
end

create_database

SchemaDev::Rspec.setup

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.warnings = true
  config.before(:each) do
    SchemaMonkey.reset_for_rspec
  end
end

SimpleCov.command_name "[ruby #{RUBY_VERSION} - ActiveRecord #{::ActiveRecord::VERSION::STRING} - #{ActiveRecord::Base.connection.adapter_name}]"
