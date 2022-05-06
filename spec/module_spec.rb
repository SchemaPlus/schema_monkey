# frozen_string_literal: true

require 'spec_helper'

describe SchemaMonkey::Module do

  describe "descendants" do

    it "doesn't fail if descendant contains a BasicObject" do
      mod = Module.new
      child = Module.new
      basic = BasicObject.new

      mod.const_set "Child", child
      mod.const_set "Basic", basic
      expect(SchemaMonkey::Module.descendants(mod)).to eq [child]
    end
  end

end
