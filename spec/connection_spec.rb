require 'spec_helper'

describe "Connection" do

  it "is connected" do
    expect(ActiveRecord::Base).to be_connected
  end

  it "re-opens without failure" do
    expect { ActiveRecord::Base.establish_connection :schema_dev }.to_not raise_error
    expect(ActiveRecord::Base.connection).to_not be_nil
    expect(ActiveRecord::Base).to be_connected
  end

end
