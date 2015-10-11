require 'spec_helper'

describe SchemaMonkey do

  it "doesn't register same client's middleware twice" do
    base = Module.new.tap(&it.module_eval(<<-END))
      module Middleware
        module Group
          module Stack
            ENV = [:result]
          end
        end
      end
    END
    mod = Module.new.tap(&it.module_eval(<<-END))
      module Middleware
        module Group
          module Stack
            def after(env)
              env.result += 1
            end
          end
        end
      end
    END

    SchemaMonkey.register(base)
    expect( SchemaMonkey::Middleware::Group::Stack.start(result: 0) {}.result ).to eq 0
    SchemaMonkey.register(mod)
    expect( SchemaMonkey::Middleware::Group::Stack.start(result: 0) {}.result ).to eq 1
    SchemaMonkey.register(mod)
    expect( SchemaMonkey::Middleware::Group::Stack.start(result: 0) {}.result ).to eq 1
  end

  it "doesn't register same client's ActiveRecord extensions twice" do
    mod = Module.new.tap(&it.module_eval(<<-END))
      module ActiveRecord
        module Base
          def monkey_test
            (super rescue 0) + 1
          end
        end
      end
    END
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table "dummy", force: :cascade
    end
    record = Class.new(ActiveRecord::Base).tap{ |kls| kls.table_name = "dummy" }.new
    SchemaMonkey.register mod
    expect( record.monkey_test ).to eq 1
    SchemaMonkey.register mod
    expect( record.monkey_test ).to eq 1
  end

end
