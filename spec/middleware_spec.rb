require 'spec_helper'

describe SchemaMonkey::Middleware do

  context "register new hook" do

    Given {
      SchemaMonkey.register Module.new.tap(&it.module_eval(<<-END))
        module Middleware
          module Migration
            module TestHook
              ENV = [:result]
            end
          end
        end
      END
    }

    When { SchemaMonkey.insert }

    Then { expect(defined?(SchemaMonkey::Middleware::Migration::TestHook)).to be_truthy }

    after(:each) { SchemaMonkey::Middleware::Migration.send :remove_const, :TestHook rescue nil }

    context "register client1" do

      Given { SchemaMonkey.register make_client(1) }

      When(:env) { SchemaMonkey::Middleware::Migration::TestHook.start result: [] }

      Then { expect(env.result).to eq [:before1, :around_pre1, :implementation1, :around_post1, :after1 ] }

      context "register client2" do

        Given { SchemaMonkey.register make_client(2) }

        Then { expect(env.result).to eq [:before1, :before2, :around_pre1, :around_pre2, :implementation2, :around_post2, :around_post1, :after1, :after2 ] }
      end
    end
  end

  def make_client(n)
    Module.new.tap(&it.module_eval(<<-END))
      module Middleware
        module Migration
          module TestHook
            def before(env)
              env.result << :"before#{n}"
            end

            def after(env)
              env.result << :"after#{n}"
            end

            def around(env)
              env.result << :"around_pre#{n}"
              continue env
              env.result << :"around_post#{n}"
            end

            def implementation(env)
              env.result << :"implementation#{n}"
            end
          end
        end
      end
    END
  end
end
