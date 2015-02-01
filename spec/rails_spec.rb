require 'spec_helper'
require 'rails/all'
require 'schema_monkey/rails'

describe SchemaMonkey::Rails do

  Given {
    # minimial setup for a rails app
    Kernel.const_set "Dummy", Class.new(Rails::Application) { config.eager_load = true }
    ENV['DATABASE_URL'] = "#{SchemaDev::Rspec.db_configuration[:adapter]}://localhost/dummy"
  }

  Given(:client) {
    Module.new do
      def self.insert
        @inserted = true
      end
      def self.inserted?
        @inserted
      end
    end
  }

  Given { SchemaMonkey.register(client) }

  When {
    Rails.application.initialize!
  }

  Then { expect(client).to be_inserted }

end
