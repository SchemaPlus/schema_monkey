require 'spec_helper'
require 'rails/all'
require 'schema_monkey/rails'

describe SchemaMonkey::Rails do


  before(:all) do
    # minimial setup for a rails app
    Kernel.const_set "Dummy", Class.new(Rails::Application) { config.eager_load = true }
    ENV['DATABASE_URL'] = "#{SchemaDev::Rspec.db_configuration[:adapter]}://localhost/dummy"

    @client = Module.new do
      def self.insert
        @inserted = true
      end
      def self.inserted?
        @inserted
      end
      def self.reset
        @inserted = false
      end
    end

    SchemaMonkey.register(@client)

    Rake.application = Rake::Application.new
    Rails.application.load_tasks
    Rails.application.initialize!
  end

  it "inserts client into app" do
    expect(@client).to be_inserted
  end

  it "inserts client into rake" do
    @client.reset
    expect { Rake::Task["db:schema:dump"].invoke }.to raise_error(Errno::ENOENT)
    expect(@client).to be_inserted
  end

end
