module SchemaMonkey::Tool
  module Rake
    TASKS_PATH = Pathname.new(__FILE__).dirname + "tasks"

    def self.insert(*task_names)
      ::Rake.load_rakefile TASKS_PATH + "insert.rake"
      task_names.each do |name|
        ::Rake.application.lookup(name).enhance(["schema_monkey:insert"])
      end
    end
  end
end
