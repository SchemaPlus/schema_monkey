require 'spec_helper'

$client_count = 0

describe SchemaMonkey::ActiveRecord do

  When(:result) {
    SchemaMonkey.register(client)
    SchemaMonkey.insert
    ActiveRecord::Base.establish_connection :schema_dev
    ActiveRecord::Base.connection
  }

  [false, true].each do |class_methods|
    suffix = class_methods ? " class methods" : ""

    [:prepend, :include].each do |mode|

      context "with #{mode} general module"+suffix do
        Given(:client) { make_client('ConnectionAdapters::SchemaStatements', mode: mode, class_methods: class_methods) }
        Then { expect_inserted(ActiveRecord::ConnectionAdapters::SchemaStatements, client.module, mode, class_methods) }
      end

      SchemaMonkey::DBMS.each do |dbm|

        context "with #{mode} #{dbm} module"+suffix do
          Given(:client) { make_client("ConnectionAdapters::#{dbm}::SchemaStatements", mode: mode, class_methods: class_methods) }

          SchemaMonkey::DBMS.each do |loaded_dbm|

            context "if using #{loaded_dbm}", loaded_dbm.to_s.downcase.to_sym => :only do
              if dbm == loaded_dbm
                Then { expect_inserted(ActiveRecord::ConnectionAdapters::SchemaStatements, client.module, mode, class_methods) }
              else
                Then { expect_not_inserted(ActiveRecord::ConnectionAdapters::SchemaStatements, client.module, class_methods) }
              end
            end
          end
        end
      end

    end
  end

  context "with invalid module" do
    Given(:client) { make_client('ConnectionAdapters::NoSuchModule') }
    Then { expect(result).to have_failed(SchemaMonkey::InsertionError) }
  end

  private

  def expect_inserted(base, mod, mode, class_methods)
    base = base.singleton_class if class_methods
    actual = base.ancestors.select{|a| [base, mod].include? a}
    expected = case mode
               when :prepend then [mod, base]
               when :include then [base, mod]
               end
    expect(actual).to eq expected
  end

  def expect_not_inserted(base, mod, class_methods)
    base = base.singleton_class if class_methods
    expect(base.ancestors).not_to include mod
  end

  def make_client(path, mode: nil, class_methods: nil)
    name = "TestActiveRecord#{$client_count}"
    $client_count += 1
    Object.send :remove_const, name if Object.const_defined? name
    Object.const_set name, Module.new.tap { |client|
      path += "::ClassMethods" if class_methods
      sub = SchemaMonkey::Module.mkpath(client, 'ActiveRecord::' + path)
      client.singleton_class.send(:define_method, :module) { sub }
      sub.singleton_class.send(:define_method, :included) {|base|} if mode == :include
    }
  end


end
