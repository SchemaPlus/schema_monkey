require 'spec_helper'

describe SchemaMonkey::Middleware do

  When(:insertion) { SchemaMonkey.insert }

  context "with stack registered" do

    Given { SchemaMonkey.register make_definition }

    Then { expect(defined?(SchemaMonkey::Middleware::Group::Stack)).to be_truthy }

    context "when start with inline implementation" do

      When(:env) { SchemaMonkey::Middleware::Group::Stack.start result: [] { |env| env.result << :inline } }

      Then { expect(env.result).to eq [:inline] }

      context "if register client1" do

        Given { SchemaMonkey.register make_client(1) }

        Then { expect(env.result).to eq [:before1, :around_pre1, :implement1, :around_post1, :after1 ] }

        context "if register client2" do

          Given { SchemaMonkey.register make_client(2) }

          Then { expect(env.result).to eq [:before1, :before2, :around_pre1, :around_pre2, :implement2, :around_post2, :around_post1, :after1, :after2 ] }
        end
      end
    end

    context "if register again" do
      Given { SchemaMonkey.register make_definition }
      Then { expect(insertion).to have_failed(SchemaMonkey::MiddlewareError, /already defined/i) }
    end
  end

  context "without stack registered" do
    context "if register client1" do
      Given { SchemaMonkey.register make_client(1) }

      Then { expect(insertion).to have_failed(SchemaMonkey::MiddlewareError, /no stack/i) }
    end
  end


  def make_definition
    Module.new.tap(&it.module_eval(<<-END))
      module Middleware
        module Group
          module Stack
            ENV = [:result]
          end
        end
      end
    END
  end

  def make_client(n)
    Module.new.tap(&it.module_eval(<<-END))
      module Middleware
        module Group
          module Stack
            def before(env)
              env.result << :"before#{n}"
            end

            def after(env)
              env.result << :"after#{n}"
            end

            def around(env)
              env.result << :"around_pre#{n}"
              yield env
              env.result << :"around_post#{n}"
            end

            def implement(env)
              env.result << :"implement#{n}"
            end
          end
        end
      end
    END
  end
end
