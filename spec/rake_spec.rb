require 'spec_helper'
require 'rake'

describe SchemaMonkey::Rake do

  context "insertion" do
    Given(:results) { [] }

    Given {
      allow(SchemaMonkey).to receive(:insert) { results << :schema_monkey }
    }

    Given {
      Rake.application = Rake::Application.new
      Rake::Task.define_task(:test1) { results << :test1 }
      Rake::Task.define_task(:test2) { results << :test2 }
      Rake::Task.define_task(:test3) { results << :test3 }
    }

    Given { SchemaMonkey::Rake.insert(:test1, :test2) }


    context "enhanced task 1" do
      When { Rake.application.invoke_task :test1 }
      Then { expect(results).to eq [:schema_monkey, :test1] }
    end

    context "enhanced task 2" do
      When { Rake.application.invoke_task :test2 }
      Then { expect(results).to eq [:schema_monkey, :test2] }
    end

    context "unenhanced task 3" do
      When { Rake.application.invoke_task :test3 }
      Then { expect(results).to eq [:test3] }
    end
  end

  end
