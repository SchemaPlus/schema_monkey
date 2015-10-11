require 'spec_helper'

describe SchemaMonkey do

  it "doesn't register same client twice" do
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

end
